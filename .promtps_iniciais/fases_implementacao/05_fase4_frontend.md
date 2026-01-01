# Fase 4 - Frontend (Web App)

## Objetivo
Criar a interface web do usuário: dashboard de viagens, visualização de documentos ricos, chat integrado e painel de administração.

## Entradas
- Fase 3 completa (Core AI funcionando)
- API Gateway configurado
- Cognito para autenticação

## Saídas
- Web App React funcionando
- Dashboard de viagens
- Visualização de documentos/roteiros
- Chat web integrado com o agente
- Sistema de autenticação completo

## Duração Estimada: 3 semanas

---

## 🚨 Mudanças Arquiteturais Importantes

Esta fase foi atualizada para refletir decisões do arquivo [00_arquitetura.md](./00_arquitetura.md):

1. **DocumentViewer Completo**: Adicionado Passo 4.8 com componente rico:
   - Iframe viewer para HTML responsivo
   - Ações: Download PDF, Compartilhar, Histórico de versões
   - Notificações de versão mais recente
   - Dialog de histórico com detalhes de mudanças

2. **PWA Único Adaptativo**: Frontend usa breakpoints Material UI M3:
   - Mobile (0-599px): Layout vertical
   - Tablet (600-1023px): Grid 2 colunas
   - Desktop (1024+): Grid 3 colunas com sidebar

3. **Vite ao invés de CRA**:
   - HMR instantâneo, bundles 40-60% menores
   - Zero-config para TypeScript

4. **Login Múltiplo**: Suporte a Email/Microsoft/Google OAuth

---

## Semana 1: Setup + Autenticação + Dashboard

### Passo 4.1: Criar Projeto React

```bash
cd apps

# Criar projeto com Vite
npm create vite@latest web-client -- --template react-ts

cd web-client

# Instalar dependências
npm install @mui/material @emotion/react @emotion/styled
npm install @mui/icons-material
npm install react-router-dom
npm install @tanstack/react-query
npm install axios
npm install amazon-cognito-identity-js
npm install date-fns
npm install react-markdown
npm install @react-google-maps/api

# Dev dependencies
npm install -D @types/node
```

### Passo 4.2: Estrutura de Pastas

```
apps/web-client/
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── Layout.tsx
│   │   │   ├── Navbar.tsx
│   │   │   └── Loading.tsx
│   │   ├── auth/
│   │   │   ├── LoginForm.tsx
│   │   │   ├── SignupForm.tsx
│   │   │   └── ProtectedRoute.tsx
│   │   ├── chat/
│   │   │   ├── ChatWindow.tsx
│   │   │   ├── MessageBubble.tsx
│   │   │   └── RichCard.tsx
│   │   ├── trip/
│   │   │   ├── TripCard.tsx
│   │   │   ├── TripTimeline.tsx
│   │   │   ├── TripMap.tsx
│   │   │   └── TripBudget.tsx
│   │   └── documents/
│   │       ├── DocumentViewer.tsx
│   │       └── ItineraryView.tsx
│   ├── pages/
│   │   ├── Home.tsx
│   │   ├── Login.tsx
│   │   ├── Signup.tsx
│   │   ├── Dashboard.tsx
│   │   ├── TripDetail.tsx
│   │   ├── Chat.tsx
│   │   └── Documents.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useTrips.ts
│   │   └── useChat.ts
│   ├── services/
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   └── websocket.ts
│   ├── contexts/
│   │   └── AuthContext.tsx
│   ├── types/
│   │   └── index.ts
│   ├── theme/
│   │   └── index.ts
│   ├── App.tsx
│   └── main.tsx
├── public/
├── index.html
├── vite.config.ts
└── package.json
```

### Passo 4.3: Configuração do Tema (Material UI M3)

**src/theme/index.ts**:

```typescript
import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#6750A4',      // M3 Primary
      light: '#EADDFF',
      dark: '#21005D',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: '#625B71',
      light: '#E8DEF8',
      dark: '#1D192B',
    },
    error: {
      main: '#B3261E',
      light: '#F9DEDC',
    },
    background: {
      default: '#FFFBFE',
      paper: '#FFFFFF',
    },
    surface: {
      main: '#FFFBFE',
      variant: '#E7E0EC',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontSize: '2.5rem',
      fontWeight: 400,
    },
    h2: {
      fontSize: '2rem',
      fontWeight: 400,
    },
    h3: {
      fontSize: '1.5rem',
      fontWeight: 500,
    },
    body1: {
      fontSize: '1rem',
      lineHeight: 1.5,
    },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 20,
          textTransform: 'none',
          fontWeight: 500,
          padding: '10px 24px',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 12,
          },
        },
      },
    },
  },
});
```

### Passo 4.4: Serviço de Autenticação

**src/services/auth.ts**:

```typescript
import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails,
  CognitoUserAttribute,
} from 'amazon-cognito-identity-js';

const poolData = {
  UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
};

const userPool = new CognitoUserPool(poolData);

export interface SignUpData {
  email: string;
  password: string;
  name: string;
  phone?: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export const authService = {
  signUp: (data: SignUpData): Promise<CognitoUser> => {
    return new Promise((resolve, reject) => {
      const attributeList = [
        new CognitoUserAttribute({ Name: 'email', Value: data.email }),
        new CognitoUserAttribute({ Name: 'name', Value: data.name }),
      ];

      if (data.phone) {
        attributeList.push(
          new CognitoUserAttribute({ Name: 'phone_number', Value: data.phone })
        );
      }

      userPool.signUp(
        data.email,
        data.password,
        attributeList,
        [],
        (err, result) => {
          if (err) {
            reject(err);
          } else {
            resolve(result!.user);
          }
        }
      );
    });
  },

  confirmSignUp: (email: string, code: string): Promise<void> => {
    return new Promise((resolve, reject) => {
      const cognitoUser = new CognitoUser({
        Username: email,
        Pool: userPool,
      });

      cognitoUser.confirmRegistration(code, true, (err, result) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  },

  login: (data: LoginData): Promise<string> => {
    return new Promise((resolve, reject) => {
      const cognitoUser = new CognitoUser({
        Username: data.email,
        Pool: userPool,
      });

      const authDetails = new AuthenticationDetails({
        Username: data.email,
        Password: data.password,
      });

      cognitoUser.authenticateUser(authDetails, {
        onSuccess: (result) => {
          const token = result.getIdToken().getJwtToken();
          localStorage.setItem('token', token);
          resolve(token);
        },
        onFailure: (err) => {
          reject(err);
        },
      });
    });
  },

  logout: (): void => {
    const cognitoUser = userPool.getCurrentUser();
    if (cognitoUser) {
      cognitoUser.signOut();
    }
    localStorage.removeItem('token');
  },

  getCurrentUser: (): CognitoUser | null => {
    return userPool.getCurrentUser();
  },

  getToken: (): Promise<string | null> => {
    return new Promise((resolve) => {
      const cognitoUser = userPool.getCurrentUser();
      if (!cognitoUser) {
        resolve(null);
        return;
      }

      cognitoUser.getSession((err: any, session: any) => {
        if (err || !session.isValid()) {
          resolve(null);
        } else {
          resolve(session.getIdToken().getJwtToken());
        }
      });
    });
  },
};
```

### Passo 4.5: API Client

**src/services/api.ts**:

```typescript
import axios from 'axios';
import { authService } from './auth';

const API_BASE_URL = import.meta.env.VITE_API_URL;

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para adicionar token
api.interceptors.request.use(async (config) => {
  const token = await authService.getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor para tratar erros
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      authService.logout();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Tipos
export interface Trip {
  trip_id: string;
  name: string;
  status: string;
  destinations: string[];
  start_date?: string;
  end_date?: string;
  members_count: number;
  budget?: {
    total_limit: number;
    spent: number;
    currency: string;
  };
}

export interface ChatMessage {
  id: string;
  sender: 'USER' | 'AGENT';
  content: string;
  timestamp: string;
  type: 'text' | 'rich_card' | 'location' | 'document';
  payload?: any;
}

// API Methods
export const tripsApi = {
  list: () => api.get<Trip[]>('/trips'),
  get: (tripId: string) => api.get<Trip>(`/trips/${tripId}`),
  create: (name: string) => api.post<Trip>('/trips', { name }),
  getDashboard: (tripId: string) => api.get(`/trips/${tripId}/dashboard`),
  getDocuments: (tripId: string) => api.get(`/trips/${tripId}/documents`),
};

export const chatApi = {
  send: (tripId: string | null, message: string) =>
    api.post('/chat', { trip_id: tripId, prompt: message }),
  getHistory: (tripId: string) => api.get<ChatMessage[]>(`/chat/${tripId}/history`),
};

export default api;
```

### Passo 4.6: Contexto de Autenticação

**src/contexts/AuthContext.tsx**:

```typescript
import React, { createContext, useContext, useState, useEffect } from 'react';
import { authService, LoginData, SignUpData } from '../services/auth';

interface User {
  email: string;
  name: string;
}

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (data: LoginData) => Promise<void>;
  signUp: (data: SignUpData) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const cognitoUser = authService.getCurrentUser();
      if (cognitoUser) {
        const token = await authService.getToken();
        if (token) {
          // Decodificar token para obter dados do usuário
          const payload = JSON.parse(atob(token.split('.')[1]));
          setUser({
            email: payload.email,
            name: payload.name || payload.email,
          });
        }
      }
    } catch (error) {
      console.error('Auth check failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (data: LoginData) => {
    const token = await authService.login(data);
    const payload = JSON.parse(atob(token.split('.')[1]));
    setUser({
      email: payload.email,
      name: payload.name || payload.email,
    });
  };

  const signUp = async (data: SignUpData) => {
    await authService.signUp(data);
  };

  const logout = () => {
    authService.logout();
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        login,
        signUp,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

---

## Semana 2: Dashboard + Trip Detail

### Passo 4.7: Página Dashboard

**src/pages/Dashboard.tsx**:

```typescript
import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  Chip,
  Fab,
  Skeleton,
} from '@mui/material';
import {
  Add as AddIcon,
  FlightTakeoff,
  CalendarMonth,
  Group,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { tripsApi, Trip } from '../services/api';

const statusColors: Record<string, 'default' | 'primary' | 'secondary' | 'success' | 'warning'> = {
  KNOWLEDGE: 'default',
  PLANNING: 'primary',
  CONTRACTING: 'secondary',
  CONCIERGE: 'success',
  MEMORIES: 'warning',
};

const statusLabels: Record<string, string> = {
  KNOWLEDGE: '📝 Conhecimento',
  PLANNING: '🗺️ Planejamento',
  CONTRACTING: '📋 Contratação',
  CONCIERGE: '✈️ Em viagem',
  MEMORIES: '📸 Memórias',
};

const TripCard: React.FC<{ trip: Trip }> = ({ trip }) => {
  const navigate = useNavigate();

  return (
    <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <CardContent sx={{ flexGrow: 1 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
          <Typography variant="h6" component="h2">
            {trip.name}
          </Typography>
          <Chip
            label={statusLabels[trip.status] || trip.status}
            color={statusColors[trip.status]}
            size="small"
          />
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <FlightTakeoff fontSize="small" color="action" />
          <Typography variant="body2" color="text.secondary">
            {trip.destinations?.join(' → ') || 'Destinos não definidos'}
          </Typography>
        </Box>

        {trip.start_date && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
            <CalendarMonth fontSize="small" color="action" />
            <Typography variant="body2" color="text.secondary">
              {trip.start_date} - {trip.end_date}
            </Typography>
          </Box>
        )}

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Group fontSize="small" color="action" />
          <Typography variant="body2" color="text.secondary">
            {trip.members_count} viajantes
          </Typography>
        </Box>

        {trip.budget && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Orçamento: {trip.budget.currency} {trip.budget.spent.toLocaleString()} / {trip.budget.total_limit.toLocaleString()}
            </Typography>
            <Box
              sx={{
                mt: 1,
                height: 8,
                bgcolor: 'grey.200',
                borderRadius: 4,
                overflow: 'hidden',
              }}
            >
              <Box
                sx={{
                  height: '100%',
                  width: `${(trip.budget.spent / trip.budget.total_limit) * 100}%`,
                  bgcolor: 'primary.main',
                  borderRadius: 4,
                }}
              />
            </Box>
          </Box>
        )}
      </CardContent>

      <CardActions>
        <Button size="small" onClick={() => navigate(`/trips/${trip.trip_id}`)}>
          Ver detalhes
        </Button>
        <Button size="small" onClick={() => navigate(`/chat?trip=${trip.trip_id}`)}>
          Conversar
        </Button>
      </CardActions>
    </Card>
  );
};

export const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const { data: trips, isLoading } = useQuery({
    queryKey: ['trips'],
    queryFn: () => tripsApi.list().then((res) => res.data),
  });

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 4 }}>
        <Typography variant="h4" component="h1">
          Minhas Viagens
        </Typography>
      </Box>

      {isLoading ? (
        <Grid container spacing={3}>
          {[1, 2, 3].map((i) => (
            <Grid item xs={12} sm={6} md={4} key={i}>
              <Skeleton variant="rectangular" height={200} sx={{ borderRadius: 2 }} />
            </Grid>
          ))}
        </Grid>
      ) : trips?.length === 0 ? (
        <Box
          sx={{
            textAlign: 'center',
            py: 8,
            bgcolor: 'grey.50',
            borderRadius: 4,
          }}
        >
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Você ainda não tem viagens
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
            Comece a planejar sua próxima aventura!
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/chat')}
          >
            Criar viagem
          </Button>
        </Box>
      ) : (
        <Grid container spacing={3}>
          {trips?.map((trip) => (
            <Grid item xs={12} sm={6} md={4} key={trip.trip_id}>
              <TripCard trip={trip} />
            </Grid>
          ))}
        </Grid>
      )}

      <Fab
        color="primary"
        aria-label="Nova viagem"
        sx={{ position: 'fixed', bottom: 24, right: 24 }}
        onClick={() => navigate('/chat')}
      >
        <AddIcon />
      </Fab>
    </Container>
  );
};
```

### Passo 4.8: Página de Detalhes da Viagem

**src/pages/TripDetail.tsx**:

```typescript
import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Paper,
  Tabs,
  Tab,
  Button,
  Chip,
  Grid,
  Card,
  CardContent,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  Timeline,
  TimelineItem,
  TimelineSeparator,
  TimelineConnector,
  TimelineContent,
  TimelineDot,
} from '@mui/lab';
import {
  Chat as ChatIcon,
  Description,
  Flight,
  Hotel,
  Attractions,
  Restaurant,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { tripsApi } from '../services/api';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => (
  <div hidden={value !== index}>
    {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
  </div>
);

const eventIcons: Record<string, React.ReactElement> = {
  FLIGHT: <Flight />,
  HOTEL: <Hotel />,
  TOUR: <Attractions />,
  RESTAURANT: <Restaurant />,
};

export const TripDetail: React.FC = () => {
  const { tripId } = useParams<{ tripId: string }>();
  const navigate = useNavigate();
  const [tabValue, setTabValue] = React.useState(0);

  const { data: dashboard, isLoading } = useQuery({
    queryKey: ['trip-dashboard', tripId],
    queryFn: () => tripsApi.getDashboard(tripId!).then((res) => res.data),
    enabled: !!tripId,
  });

  const { data: documents } = useQuery({
    queryKey: ['trip-documents', tripId],
    queryFn: () => tripsApi.getDocuments(tripId!).then((res) => res.data),
    enabled: !!tripId,
  });

  if (isLoading) {
    return <Typography>Carregando...</Typography>;
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* Header */}
      <Paper sx={{ p: 3, mb: 3, background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', color: 'white' }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography variant="h4" gutterBottom>
              🌍 {dashboard?.title}
            </Typography>
            <Typography variant="body1">
              {dashboard?.dates?.start} → {dashboard?.dates?.end} ({dashboard?.dates?.totalDays} dias)
            </Typography>
          </Box>
          <Chip
            label={dashboard?.status}
            sx={{ bgcolor: 'rgba(255,255,255,0.2)', color: 'white' }}
          />
        </Box>

        <Grid container spacing={2} sx={{ mt: 2 }}>
          <Grid item xs={4}>
            <Paper sx={{ p: 2, bgcolor: 'rgba(255,255,255,0.1)' }}>
              <Typography variant="h5">{dashboard?.dates?.totalDays}</Typography>
              <Typography variant="body2">dias</Typography>
            </Paper>
          </Grid>
          <Grid item xs={4}>
            <Paper sx={{ p: 2, bgcolor: 'rgba(255,255,255,0.1)' }}>
              <Typography variant="h5">{dashboard?.members?.length}</Typography>
              <Typography variant="body2">viajantes</Typography>
            </Paper>
          </Grid>
          <Grid item xs={4}>
            <Paper sx={{ p: 2, bgcolor: 'rgba(255,255,255,0.1)' }}>
              <Typography variant="h5">
                {dashboard?.budget?.currency} {dashboard?.budget?.currentSpent?.toLocaleString()}
              </Typography>
              <Typography variant="body2">gasto</Typography>
            </Paper>
          </Grid>
        </Grid>
      </Paper>

      {/* Actions */}
      <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<ChatIcon />}
          onClick={() => navigate(`/chat?trip=${tripId}`)}
        >
          Conversar com agente
        </Button>
        <Button
          variant="outlined"
          startIcon={<Description />}
          onClick={() => window.open(documents?.[0]?.url, '_blank')}
          disabled={!documents?.length}
        >
          Ver roteiro completo
        </Button>
      </Box>

      {/* Tabs */}
      <Paper>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
          <Tab label="Timeline" />
          <Tab label="Participantes" />
          <Tab label="Documentos" />
          <Tab label="Orçamento" />
        </Tabs>

        <TabPanel value={tabValue} index={0}>
          <Timeline position="alternate">
            {dashboard?.timeline?.map((day: any, index: number) => (
              <TimelineItem key={day.date}>
                <TimelineSeparator>
                  <TimelineDot color={index === 0 ? 'primary' : 'grey'} />
                  {index < dashboard.timeline.length - 1 && <TimelineConnector />}
                </TimelineSeparator>
                <TimelineContent>
                  <Card>
                    <CardContent>
                      <Typography variant="subtitle2" color="text.secondary">
                        Dia {day.dayNumber} • {day.date}
                      </Typography>
                      <Typography variant="h6">{day.city}</Typography>
                      
                      <List dense>
                        {day.events?.map((event: any) => (
                          <ListItem key={event.id}>
                            <ListItemIcon>
                              {eventIcons[event.type] || <Attractions />}
                            </ListItemIcon>
                            <ListItemText
                              primary={`${event.time} - ${event.title}`}
                              secondary={event.details}
                            />
                          </ListItem>
                        ))}
                      </List>
                    </CardContent>
                  </Card>
                </TimelineContent>
              </TimelineItem>
            ))}
          </Timeline>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <List>
            {dashboard?.members?.map((member: any) => (
              <React.Fragment key={member.name}>
                <ListItem>
                  <ListItemText
                    primary={member.name}
                    secondary={member.role}
                  />
                  {member.pendingTasks > 0 && (
                    <Chip
                      label={`${member.pendingTasks} tarefas`}
                      color="warning"
                      size="small"
                    />
                  )}
                </ListItem>
                <Divider />
              </React.Fragment>
            ))}
          </List>
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <List>
            {documents?.map((doc: any) => (
              <ListItem
                key={doc.id}
                button
                onClick={() => window.open(doc.url, '_blank')}
              >
                <ListItemIcon>
                  <Description />
                </ListItemIcon>
                <ListItemText
                  primary={doc.type}
                  secondary={`Versão ${doc.version} • ${doc.created_at}`}
                />
              </ListItem>
            ))}
          </List>
        </TabPanel>

        <TabPanel value={tabValue} index={3}>
          <Box sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              {dashboard?.budget?.currency} {dashboard?.budget?.currentSpent?.toLocaleString()} / {dashboard?.budget?.totalLimit?.toLocaleString()}
            </Typography>
            <Box sx={{ height: 20, bgcolor: 'grey.200', borderRadius: 2, overflow: 'hidden' }}>
              <Box
                sx={{
                  height: '100%',
                  width: `${(dashboard?.budget?.currentSpent / dashboard?.budget?.totalLimit) * 100}%`,
                  bgcolor: 'primary.main',
                }}
              />
            </Box>
            {dashboard?.budget?.alerts?.map((alert: string, i: number) => (
              <Typography key={i} color="warning.main" variant="body2" sx={{ mt: 1 }}>
                ⚠️ {alert}
              </Typography>
            ))}
          </Box>
        </TabPanel>
      </Paper>
    </Container>
  );
};
```

---

## Semana 3: Chat Interface

### Passo 4.9: Componente de Chat

**src/components/chat/ChatWindow.tsx**:

```typescript
import React, { useState, useRef, useEffect } from 'react';
import {
  Box,
  Paper,
  TextField,
  IconButton,
  Typography,
  CircularProgress,
  Avatar,
} from '@mui/material';
import { Send, SmartToy, Person } from '@mui/icons-material';
import ReactMarkdown from 'react-markdown';
import { useMutation } from '@tanstack/react-query';
import { chatApi, ChatMessage } from '../../services/api';
import { RichCard } from './RichCard';

interface ChatWindowProps {
  tripId?: string;
  initialMessages?: ChatMessage[];
}

export const ChatWindow: React.FC<ChatWindowProps> = ({ tripId, initialMessages = [] }) => {
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [input, setInput] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMutation = useMutation({
    mutationFn: (message: string) => chatApi.send(tripId || null, message),
    onMutate: (message) => {
      // Adicionar mensagem do usuário imediatamente
      const userMessage: ChatMessage = {
        id: `temp-${Date.now()}`,
        sender: 'USER',
        content: message,
        timestamp: new Date().toISOString(),
        type: 'text',
      };
      setMessages((prev) => [...prev, userMessage]);
    },
    onSuccess: (response) => {
      // Adicionar resposta do agente
      const agentMessage: ChatMessage = {
        id: `agent-${Date.now()}`,
        sender: 'AGENT',
        content: response.data.result,
        timestamp: new Date().toISOString(),
        type: response.data.type || 'text',
        payload: response.data.payload,
      };
      setMessages((prev) => [...prev, agentMessage]);
    },
  });

  const handleSend = () => {
    if (!input.trim() || sendMutation.isPending) return;
    sendMutation.mutate(input);
    setInput('');
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <Paper
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
      }}
    >
      {/* Messages Area */}
      <Box
        sx={{
          flexGrow: 1,
          overflow: 'auto',
          p: 2,
          display: 'flex',
          flexDirection: 'column',
          gap: 2,
        }}
      >
        {messages.length === 0 && (
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <SmartToy sx={{ fontSize: 64, color: 'grey.400', mb: 2 }} />
            <Typography variant="h6" color="text.secondary">
              Olá! Sou o n-agent 👋
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Como posso ajudar com sua viagem hoje?
            </Typography>
          </Box>
        )}

        {messages.map((message) => (
          <Box
            key={message.id}
            sx={{
              display: 'flex',
              justifyContent: message.sender === 'USER' ? 'flex-end' : 'flex-start',
              gap: 1,
            }}
          >
            {message.sender === 'AGENT' && (
              <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                <SmartToy fontSize="small" />
              </Avatar>
            )}

            <Paper
              sx={{
                p: 2,
                maxWidth: '70%',
                bgcolor: message.sender === 'USER' ? 'primary.main' : 'grey.100',
                color: message.sender === 'USER' ? 'white' : 'text.primary',
                borderRadius: 3,
                borderTopLeftRadius: message.sender === 'AGENT' ? 0 : 12,
                borderTopRightRadius: message.sender === 'USER' ? 0 : 12,
              }}
            >
              {message.type === 'rich_card' || message.type === 'rich_card_carousel' ? (
                <RichCard payload={message.payload} />
              ) : (
                <ReactMarkdown
                  components={{
                    p: ({ children }) => (
                      <Typography variant="body1" component="p" sx={{ mb: 1 }}>
                        {children}
                      </Typography>
                    ),
                    a: ({ href, children }) => (
                      <a
                        href={href}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ color: message.sender === 'USER' ? '#fff' : '#667eea' }}
                      >
                        {children}
                      </a>
                    ),
                  }}
                >
                  {message.content}
                </ReactMarkdown>
              )}
            </Paper>

            {message.sender === 'USER' && (
              <Avatar sx={{ bgcolor: 'grey.400', width: 32, height: 32 }}>
                <Person fontSize="small" />
              </Avatar>
            )}
          </Box>
        ))}

        {sendMutation.isPending && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
              <SmartToy fontSize="small" />
            </Avatar>
            <Paper sx={{ p: 2, bgcolor: 'grey.100', borderRadius: 3 }}>
              <CircularProgress size={20} />
            </Paper>
          </Box>
        )}

        <div ref={messagesEndRef} />
      </Box>

      {/* Input Area */}
      <Box sx={{ p: 2, borderTop: 1, borderColor: 'divider' }}>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <TextField
            fullWidth
            multiline
            maxRows={4}
            placeholder="Digite sua mensagem..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            disabled={sendMutation.isPending}
            sx={{
              '& .MuiOutlinedInput-root': {
                borderRadius: 3,
              },
            }}
          />
          <IconButton
            color="primary"
            onClick={handleSend}
            disabled={!input.trim() || sendMutation.isPending}
            sx={{
              bgcolor: 'primary.main',
              color: 'white',
              '&:hover': { bgcolor: 'primary.dark' },
              '&.Mui-disabled': { bgcolor: 'grey.300' },
            }}
          >
            <Send />
          </IconButton>
        </Box>
      </Box>
    </Paper>
  );
};
```

### Passo 4.10: Componente Rich Card

**src/components/chat/RichCard.tsx**:

```typescript
import React from 'react';
import {
  Box,
  Card,
  CardContent,
  CardMedia,
  CardActions,
  Typography,
  Button,
  Rating,
  Chip,
} from '@mui/material';

interface RichCardPayload {
  title?: string;
  cards?: Array<{
    id: string;
    title: string;
    imageUrl?: string;
    price?: string;
    rating?: number;
    highlight?: string;
    actionLink?: string;
  }>;
}

export const RichCard: React.FC<{ payload: RichCardPayload }> = ({ payload }) => {
  if (!payload.cards?.length) {
    return null;
  }

  return (
    <Box>
      {payload.title && (
        <Typography variant="subtitle1" fontWeight="bold" gutterBottom>
          {payload.title}
        </Typography>
      )}
      
      <Box
        sx={{
          display: 'flex',
          gap: 2,
          overflowX: 'auto',
          pb: 1,
          '&::-webkit-scrollbar': { height: 8 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'grey.300', borderRadius: 4 },
        }}
      >
        {payload.cards.map((card) => (
          <Card
            key={card.id}
            sx={{
              minWidth: 250,
              maxWidth: 250,
              flexShrink: 0,
            }}
          >
            {card.imageUrl && (
              <CardMedia
                component="img"
                height="120"
                image={card.imageUrl}
                alt={card.title}
              />
            )}
            <CardContent sx={{ pb: 1 }}>
              <Typography variant="subtitle2" noWrap>
                {card.title}
              </Typography>
              
              {card.rating && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, my: 0.5 }}>
                  <Rating value={card.rating} precision={0.1} size="small" readOnly />
                  <Typography variant="caption">{card.rating}</Typography>
                </Box>
              )}
              
              {card.highlight && (
                <Chip
                  label={card.highlight}
                  size="small"
                  color="primary"
                  variant="outlined"
                  sx={{ mt: 0.5 }}
                />
              )}
              
              {card.price && (
                <Typography variant="h6" color="primary" sx={{ mt: 1 }}>
                  {card.price}
                </Typography>
              )}
            </CardContent>
            
            <CardActions>
              <Button
                size="small"
                href={card.actionLink}
                target="_blank"
                rel="noopener noreferrer"
              >
                Ver mais
              </Button>
            </CardActions>
          </Card>
        ))}
      </Box>
    </Box>
  );
};
```

---

### Passo 4.8: Componente DocumentViewer

**src/components/documents/DocumentViewer.tsx**:

```typescript
import React, { useState, useEffect } from 'react';
import {
  Paper,
  Box,
  Typography,
  IconButton,
  Tooltip,
  Alert,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  List,
  ListItem,
  ListItemText,
  Chip,
  Skeleton,
} from '@mui/material';
import {
  PictureAsPdf as PdfIcon,
  Share as ShareIcon,
  History as HistoryIcon,
  Download as DownloadIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface Document {
  id: string;
  trip_id: string;
  title: string;
  type: string;
  version: string;
  created_at: string;
  html_url: string;
  pdf_url: string;
  is_current: boolean;
  has_previous_version: boolean;
  has_newer_version: boolean;
  latest_version?: string;
  page_count?: number;
  change_summary?: string;
}

interface DocumentVersion {
  version: string;
  created_at: string;
  change_summary: string;
  change_type: 'major' | 'minor';
  created_by: string;
}

interface DocumentViewerProps {
  documentId: string;
  tripId: string;
}

export const DocumentViewer: React.FC<DocumentViewerProps> = ({ documentId, tripId }) => {
  const [document, setDocument] = useState<Document | null>(null);
  const [loading, setLoading] = useState(true);
  const [showHistory, setShowHistory] = useState(false);
  const [versions, setVersions] = useState<DocumentVersion[]>([]);

  useEffect(() => {
    fetchDocument();
  }, [documentId]);

  const fetchDocument = async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/trips/${tripId}/documents/${documentId}`);
      const data = await response.json();
      setDocument(data);
    } catch (error) {
      console.error('Erro ao carregar documento:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchVersionHistory = async () => {
    try {
      const response = await fetch(`/api/trips/${tripId}/documents/${documentId}/versions`);
      const data = await response.json();
      setVersions(data);
      setShowHistory(true);
    } catch (error) {
      console.error('Erro ao carregar histórico:', error);
    }
  };

  const loadVersion = async (version: string) => {
    setLoading(true);
    try {
      const response = await fetch(`/api/trips/${tripId}/documents/${documentId}?version=${version}`);
      const data = await response.json();
      setDocument(data);
      setShowHistory(false);
    } catch (error) {
      console.error('Erro ao carregar versão:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleShare = async (url: string) => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: document?.title,
          text: `Confira o documento: ${document?.title}`,
          url: url,
        });
      } catch (error) {
        console.log('Compartilhamento cancelado');
      }
    } else {
      // Fallback: copiar para clipboard
      navigator.clipboard.writeText(url);
      alert('Link copiado para a área de transferência!');
    }
  };

  if (loading) {
    return (
      <Paper elevation={2} sx={{ overflow: 'hidden' }}>
        <Skeleton variant="rectangular" height={600} />
      </Paper>
    );
  }

  if (!document) {
    return (
      <Alert severity="error">
        Documento não encontrado
      </Alert>
    );
  }

  return (
    <>
      <Paper elevation={2} sx={{ overflow: 'hidden' }}>
        {/* Header com ações */}
        <Box
          sx={{
            p: 2,
            borderBottom: 1,
            borderColor: 'divider',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-start',
            bgcolor: 'background.paper',
          }}
        >
          <Box>
            <Typography variant="h6">{document.title}</Typography>
            <Typography variant="caption" color="text.secondary">
              Gerado em {format(new Date(document.created_at), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR })} •
              Versão {document.version}
              {document.page_count && ` • ${document.page_count} páginas`}
            </Typography>
            {document.change_summary && (
              <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                📝 {document.change_summary}
              </Typography>
            )}
          </Box>

          <Box sx={{ display: 'flex', gap: 1 }}>
            {/* Baixar PDF */}
            <Tooltip title="Baixar PDF">
              <IconButton
                onClick={() => window.open(document.pdf_url, '_blank')}
                color="primary"
              >
                <PdfIcon />
              </IconButton>
            </Tooltip>

            {/* Download direto */}
            <Tooltip title="Download">
              <IconButton
                component="a"
                href={document.pdf_url}
                download
                color="primary"
              >
                <DownloadIcon />
              </IconButton>
            </Tooltip>

            {/* Compartilhar */}
            <Tooltip title="Compartilhar">
              <IconButton
                onClick={() => handleShare(document.html_url)}
                color="primary"
              >
                <ShareIcon />
              </IconButton>
            </Tooltip>

            {/* Histórico de versões */}
            {document.has_previous_version && (
              <Tooltip title="Ver histórico">
                <IconButton onClick={fetchVersionHistory} color="primary">
                  <HistoryIcon />
                </IconButton>
              </Tooltip>
            )}
          </Box>
        </Box>

        {/* Notificação de versão mais recente */}
        {document.has_newer_version && (
          <Alert severity="info" sx={{ borderRadius: 0 }}>
            Uma versão mais recente deste documento está disponível.
            <Button
              size="small"
              onClick={() => loadVersion(document.latest_version!)}
              sx={{ ml: 2 }}
            >
              Ver versão {document.latest_version}
            </Button>
          </Alert>
        )}

        {/* Iframe viewer do documento HTML */}
        <Box sx={{ height: 600, overflow: 'auto', bgcolor: 'grey.50' }}>
          <iframe
            src={document.html_url}
            style={{
              width: '100%',
              height: '100%',
              border: 'none',
              display: 'block',
            }}
            sandbox="allow-scripts allow-same-origin"
            title={document.title}
          />
        </Box>
      </Paper>

      {/* Dialog de Histórico de Versões */}
      <Dialog
        open={showHistory}
        onClose={() => setShowHistory(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6">Histórico de Versões</Typography>
          <IconButton onClick={() => setShowHistory(false)} size="small">
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent dividers>
          <List>
            {versions.map((version, index) => (
              <ListItem
                key={version.version}
                sx={{
                  border: 1,
                  borderColor: 'divider',
                  borderRadius: 1,
                  mb: 1,
                  '&:hover': { bgcolor: 'action.hover', cursor: 'pointer' },
                }}
                onClick={() => loadVersion(version.version)}
              >
                <ListItemText
                  primary=(
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography variant="subtitle2">Versão {version.version}</Typography>
                      {index === 0 && (
                        <Chip label="Atual" size="small" color="primary" />
                      )}
                      <Chip
                        label={version.change_type === 'major' ? 'Grande alteração' : 'Ajuste'}
                        size="small"
                        color={version.change_type === 'major' ? 'error' : 'default'}
                        variant="outlined"
                      />
                    </Box>
                  )
                  secondary=(
                    <>
                      <Typography variant="body2" color="text.secondary">
                        {format(new Date(version.created_at), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR })}
                        {' • '}
                        {version.created_by}
                      </Typography>
                      <Typography variant="body2" sx={{ mt: 0.5 }}>
                        {version.change_summary}
                      </Typography>
                    </>
                  )
                />
              </ListItem>
            ))}
          </List>
        </DialogContent>
      </Dialog>
    </>
  );
};
```

**src/components/documents/ItineraryView.tsx** (wrapper específico):

```typescript
import React from 'react';
import { DocumentViewer } from './DocumentViewer';
import { useParams } from 'react-router-dom';
import { Box, Typography, Alert } from '@mui/material';

export const ItineraryView: React.FC = () => {
  const { tripId, documentId } = useParams<{ tripId: string; documentId: string }>();

  if (!tripId || !documentId) {
    return (
      <Alert severity="error">
        Parâmetros inválidos
      </Alert>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        🗺️ Itinerário da Viagem
      </Typography>
      <DocumentViewer documentId={documentId} tripId={tripId} />
    </Box>
  );
};
```

---

## Checklist de Conclusão da Fase 4

- [ ] Projeto React criado com Vite
- [ ] Tema Material UI M3 configurado
- [ ] Autenticação Cognito funcionando
- [ ] Login/Signup funcionando
- [ ] Dashboard listando viagens
- [ ] Página de detalhes da viagem
- [ ] Chat integrado com o agente
- [ ] Rich Cards renderizando corretamente
- [ ] Deploy no CloudFront/S3

---

## Deploy do Frontend

### Configurar S3 + CloudFront

```bash
# Build do projeto
cd apps/web-client
npm run build

# Criar bucket S3
aws s3 mb s3://n-agent-web-prod

# Upload dos arquivos
aws s3 sync dist/ s3://n-agent-web-prod --delete

# Configurar CloudFront (via console ou Terraform)
```

---

## Próxima Fase

Com o Frontend funcionando, siga para a **[Fase 5 - Concierge](./06_fase5_concierge.md)** onde vamos:
- Implementar sistema de alertas
- Configurar EventBridge Scheduler
- Notificações proativas via WhatsApp
- Monitoramento de voos em tempo real
