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

## Semana 4: Painel de Administração

### Passo 4.9: Setup do Admin Panel

O Admin Panel é uma aplicação React separada, acessível apenas por administradores, para gerenciar prompts, integrações, usuários e monitorar custos.

**Estrutura do Projeto**:

```bash
cd apps

# Criar projeto admin
npm create vite@latest admin-panel -- --template react-ts

cd admin-panel

# Dependências
npm install @mui/material @emotion/react @emotion/styled
npm install @mui/icons-material @mui/x-data-grid
npm install react-router-dom
npm install @tanstack/react-query
npm install axios
npm install amazon-cognito-identity-js
npm install recharts  # Para gráficos
npm install react-hook-form @hookform/resolvers zod
npm install @monaco-editor/react  # Editor de código para prompts
npm install date-fns
```

**Estrutura de Pastas**:

```
apps/admin-panel/
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── AdminLayout.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── StatsCard.tsx
│   │   ├── prompts/
│   │   │   ├── PromptEditor.tsx
│   │   │   ├── PromptVersionHistory.tsx
│   │   │   └── PromptTestPanel.tsx
│   │   ├── integrations/
│   │   │   ├── IntegrationCard.tsx
│   │   │   ├── ApiKeyManager.tsx
│   │   │   └── WebhookConfig.tsx
│   │   ├── users/
│   │   │   ├── UserTable.tsx
│   │   │   ├── UserDetail.tsx
│   │   │   └── ActivityLog.tsx
│   │   └── monitoring/
│   │       ├── CostDashboard.tsx
│   │       ├── UsageChart.tsx
│   │       └── ErrorLog.tsx
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   ├── PromptManager.tsx
│   │   ├── Integrations.tsx
│   │   ├── Users.tsx
│   │   ├── Monitoring.tsx
│   │   └── AuditLog.tsx
│   ├── hooks/
│   │   ├── useAdminAuth.ts
│   │   ├── usePrompts.ts
│   │   ├── useIntegrations.ts
│   │   └── useMetrics.ts
│   ├── services/
│   │   └── adminApi.ts
│   └── App.tsx
```

### Passo 4.10: Gestão de Prompts

Sistema para versionamento e teste de prompts dos agentes.

**src/components/prompts/PromptEditor.tsx**:

```typescript
import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Alert,
  Chip,
  Divider,
  Stack,
  Switch,
  FormControlLabel,
} from '@mui/material';
import Editor from '@monaco-editor/react';
import { Save, PlayArrow, History, Science } from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '../../services/adminApi';

interface PromptVersion {
  version: number;
  content: string;
  created_at: string;
  created_by: string;
  change_summary: string;
  is_active: boolean;
  test_results?: {
    passed: number;
    failed: number;
    last_tested: string;
  };
}

interface PromptConfig {
  agent_type: string;
  prompt_name: string;
  description: string;
  model_id: string;
  temperature: number;
  max_tokens: number;
  versions: PromptVersion[];
  active_version: number;
}

const AGENT_TYPES = [
  { id: 'router', name: 'Router Agent', model: 'amazon.nova-micro-v1:0' },
  { id: 'profile', name: 'Profile Agent', model: 'amazon.nova-lite-v1:0' },
  { id: 'planner', name: 'Planner Agent', model: 'amazon.nova-pro-v1:0' },
  { id: 'concierge', name: 'Concierge Agent', model: 'amazon.nova-lite-v1:0' },
  { id: 'document', name: 'Document Agent', model: 'anthropic.claude-3-5-sonnet-20241022-v2:0' },
  { id: 'search', name: 'Search Agent', model: 'gemini-2.0-flash' },
];

export const PromptEditor: React.FC = () => {
  const [selectedAgent, setSelectedAgent] = useState<string>('router');
  const [promptContent, setPromptContent] = useState<string>('');
  const [testInput, setTestInput] = useState<string>('');
  const [showTestPanel, setShowTestPanel] = useState(false);
  const queryClient = useQueryClient();

  const { data: promptConfig, isLoading } = useQuery({
    queryKey: ['prompt', selectedAgent],
    queryFn: () => adminApi.getPromptConfig(selectedAgent),
  });

  const saveMutation = useMutation({
    mutationFn: (data: { content: string; changeSummary: string }) =>
      adminApi.savePrompt(selectedAgent, data.content, data.changeSummary),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['prompt', selectedAgent] });
    },
  });

  const testMutation = useMutation({
    mutationFn: (input: string) =>
      adminApi.testPrompt(selectedAgent, promptContent, input),
  });

  useEffect(() => {
    if (promptConfig) {
      const activeVersion = promptConfig.versions.find(
        (v: PromptVersion) => v.version === promptConfig.active_version
      );
      if (activeVersion) {
        setPromptContent(activeVersion.content);
      }
    }
  }, [promptConfig]);

  const handleSave = () => {
    const changeSummary = prompt('Descreva as alterações feitas:');
    if (changeSummary) {
      saveMutation.mutate({ content: promptContent, changeSummary });
    }
  };

  const handleTest = () => {
    if (testInput) {
      testMutation.mutate(testInput);
    }
  };

  return (
    <Box sx={{ display: 'flex', gap: 2, height: '100%' }}>
      {/* Painel Principal */}
      <Card sx={{ flex: 2 }}>
        <CardContent>
          <Stack direction="row" spacing={2} alignItems="center" mb={2}>
            <FormControl size="small" sx={{ minWidth: 200 }}>
              <InputLabel>Agente</InputLabel>
              <Select
                value={selectedAgent}
                label="Agente"
                onChange={(e) => setSelectedAgent(e.target.value)}
              >
                {AGENT_TYPES.map((agent) => (
                  <MenuItem key={agent.id} value={agent.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {agent.name}
                      <Chip label={agent.model} size="small" variant="outlined" />
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <Button
              variant="contained"
              startIcon={<Save />}
              onClick={handleSave}
              disabled={saveMutation.isPending}
            >
              Salvar Nova Versão
            </Button>

            <Button
              variant="outlined"
              startIcon={<Science />}
              onClick={() => setShowTestPanel(!showTestPanel)}
            >
              Testar Prompt
            </Button>

            <Button variant="text" startIcon={<History />}>
              Histórico
            </Button>
          </Stack>

          {promptConfig && (
            <Alert severity="info" sx={{ mb: 2 }}>
              Versão ativa: <strong>v{promptConfig.active_version}</strong>
              {' • '}
              Modelo: <strong>{promptConfig.model_id}</strong>
              {' • '}
              Temperature: <strong>{promptConfig.temperature}</strong>
            </Alert>
          )}

          <Box sx={{ height: 500, border: 1, borderColor: 'divider', borderRadius: 1 }}>
            <Editor
              height="100%"
              defaultLanguage="markdown"
              value={promptContent}
              onChange={(value) => setPromptContent(value || '')}
              theme="vs-light"
              options={{
                minimap: { enabled: false },
                lineNumbers: 'on',
                wordWrap: 'on',
                fontSize: 14,
              }}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Painel de Teste */}
      {showTestPanel && (
        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              🧪 Testar Prompt
            </Typography>
            
            <TextField
              fullWidth
              multiline
              rows={4}
              label="Input de Teste"
              value={testInput}
              onChange={(e) => setTestInput(e.target.value)}
              placeholder="Digite uma mensagem para testar o prompt..."
              sx={{ mb: 2 }}
            />
            
            <Button
              fullWidth
              variant="contained"
              startIcon={<PlayArrow />}
              onClick={handleTest}
              disabled={testMutation.isPending}
            >
              Executar Teste
            </Button>

            {testMutation.data && (
              <Box sx={{ mt: 2 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Resposta:
                </Typography>
                <Box
                  sx={{
                    p: 2,
                    bgcolor: 'grey.100',
                    borderRadius: 1,
                    maxHeight: 300,
                    overflow: 'auto',
                    fontFamily: 'monospace',
                    fontSize: 13,
                  }}
                >
                  {testMutation.data.response}
                </Box>
                <Typography variant="caption" color="text.secondary">
                  Latência: {testMutation.data.latency_ms}ms
                  {' • '}
                  Tokens: {testMutation.data.input_tokens} in / {testMutation.data.output_tokens} out
                </Typography>
              </Box>
            )}
          </CardContent>
        </Card>
      )}
    </Box>
  );
};
```

### Passo 4.11: Configuração de Integrações

Gerenciar chaves de API e webhooks das integrações externas.

**src/pages/Integrations.tsx**:

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Alert,
  Switch,
  FormControlLabel,
  Tooltip,
  Divider,
} from '@mui/material';
import {
  Settings,
  Visibility,
  VisibilityOff,
  Refresh,
  CheckCircle,
  Error as ErrorIcon,
  Warning,
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '../services/adminApi';

interface Integration {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: 'ai' | 'travel' | 'communication' | 'storage';
  status: 'active' | 'inactive' | 'error';
  config: {
    api_key_masked: string;
    endpoint?: string;
    webhook_url?: string;
    last_health_check?: string;
    error_message?: string;
  };
  required_fields: string[];
  documentation_url: string;
}

const INTEGRATION_CATEGORIES = {
  ai: { label: 'AI/ML', color: 'primary' as const },
  travel: { label: 'Viagem', color: 'success' as const },
  communication: { label: 'Comunicação', color: 'warning' as const },
  storage: { label: 'Armazenamento', color: 'info' as const },
};

const IntegrationCard: React.FC<{
  integration: Integration;
  onConfigure: () => void;
  onTest: () => void;
}> = ({ integration, onConfigure, onTest }) => {
  const statusIcon = {
    active: <CheckCircle color="success" />,
    inactive: <Warning color="warning" />,
    error: <ErrorIcon color="error" />,
  }[integration.status];

  return (
    <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <CardContent sx={{ flex: 1 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="h3">{integration.icon}</Typography>
            <Box>
              <Typography variant="h6">{integration.name}</Typography>
              <Chip
                label={INTEGRATION_CATEGORIES[integration.category].label}
                color={INTEGRATION_CATEGORIES[integration.category].color}
                size="small"
              />
            </Box>
          </Box>
          <Tooltip title={integration.status === 'active' ? 'Ativo' : 'Inativo'}>
            {statusIcon}
          </Tooltip>
        </Box>
        
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {integration.description}
        </Typography>

        {integration.config.api_key_masked && (
          <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
            API Key: {integration.config.api_key_masked}
          </Typography>
        )}

        {integration.config.error_message && (
          <Alert severity="error" sx={{ mt: 1 }}>
            {integration.config.error_message}
          </Alert>
        )}
      </CardContent>
      
      <CardActions>
        <Button size="small" startIcon={<Settings />} onClick={onConfigure}>
          Configurar
        </Button>
        <Button size="small" startIcon={<Refresh />} onClick={onTest}>
          Testar Conexão
        </Button>
      </CardActions>
    </Card>
  );
};

export const IntegrationsPage: React.FC = () => {
  const [configDialog, setConfigDialog] = useState<Integration | null>(null);
  const [showApiKey, setShowApiKey] = useState(false);
  const [apiKeyValue, setApiKeyValue] = useState('');
  const queryClient = useQueryClient();

  const { data: integrations = [] } = useQuery({
    queryKey: ['integrations'],
    queryFn: adminApi.getIntegrations,
  });

  const updateMutation = useMutation({
    mutationFn: (data: { id: string; config: Record<string, string> }) =>
      adminApi.updateIntegration(data.id, data.config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['integrations'] });
      setConfigDialog(null);
    },
  });

  const testMutation = useMutation({
    mutationFn: (id: string) => adminApi.testIntegration(id),
  });

  const handleSave = () => {
    if (configDialog && apiKeyValue) {
      updateMutation.mutate({
        id: configDialog.id,
        config: { api_key: apiKeyValue },
      });
    }
  };

  // Agrupar por categoria
  const groupedIntegrations = integrations.reduce((acc: Record<string, Integration[]>, int: Integration) => {
    if (!acc[int.category]) acc[int.category] = [];
    acc[int.category].push(int);
    return acc;
  }, {});

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🔌 Integrações
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Gerencie as APIs e serviços conectados ao n-agent
      </Typography>

      {Object.entries(groupedIntegrations).map(([category, ints]) => (
        <Box key={category} sx={{ mb: 4 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Chip
              label={INTEGRATION_CATEGORIES[category as keyof typeof INTEGRATION_CATEGORIES].label}
              color={INTEGRATION_CATEGORIES[category as keyof typeof INTEGRATION_CATEGORIES].color}
            />
          </Typography>
          <Grid container spacing={2}>
            {ints.map((integration: Integration) => (
              <Grid item xs={12} md={6} lg={4} key={integration.id}>
                <IntegrationCard
                  integration={integration}
                  onConfigure={() => setConfigDialog(integration)}
                  onTest={() => testMutation.mutate(integration.id)}
                />
              </Grid>
            ))}
          </Grid>
        </Box>
      ))}

      {/* Dialog de Configuração */}
      <Dialog open={!!configDialog} onClose={() => setConfigDialog(null)} maxWidth="sm" fullWidth>
        <DialogTitle>
          Configurar {configDialog?.name}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <TextField
              fullWidth
              label="API Key"
              type={showApiKey ? 'text' : 'password'}
              value={apiKeyValue}
              onChange={(e) => setApiKeyValue(e.target.value)}
              placeholder="Cole a nova API key aqui..."
              InputProps={{
                endAdornment: (
                  <IconButton onClick={() => setShowApiKey(!showApiKey)}>
                    {showApiKey ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                ),
              }}
            />
            
            <Alert severity="info" sx={{ mt: 2 }}>
              A chave será armazenada criptografada no AWS Secrets Manager.
            </Alert>

            {configDialog?.documentation_url && (
              <Button
                href={configDialog.documentation_url}
                target="_blank"
                sx={{ mt: 2 }}
              >
                📚 Ver Documentação
              </Button>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfigDialog(null)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={!apiKeyValue || updateMutation.isPending}
          >
            Salvar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
```

### Passo 4.12: Dashboard de Monitoramento e Custos

Visualizar métricas de uso, custos com LLMs e erros.

**src/pages/Monitoring.tsx**:

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Chip,
  LinearProgress,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  AttachMoney,
  Chat,
  Speed,
  Error as ErrorIcon,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '../services/adminApi';
import { format, subDays } from 'date-fns';

interface StatsCardProps {
  title: string;
  value: string | number;
  change: number;
  icon: React.ReactNode;
  color: string;
}

const StatsCard: React.FC<StatsCardProps> = ({ title, value, change, icon, color }) => (
  <Card>
    <CardContent>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box>
          <Typography variant="body2" color="text.secondary">
            {title}
          </Typography>
          <Typography variant="h4" sx={{ my: 1 }}>
            {value}
          </Typography>
          <Chip
            size="small"
            icon={change >= 0 ? <TrendingUp /> : <TrendingDown />}
            label={`${change >= 0 ? '+' : ''}${change}%`}
            color={change >= 0 ? 'success' : 'error'}
          />
        </Box>
        <Box
          sx={{
            bgcolor: color,
            borderRadius: 2,
            p: 1.5,
            color: 'white',
          }}
        >
          {icon}
        </Box>
      </Box>
    </CardContent>
  </Card>
);

const MODEL_COLORS: Record<string, string> = {
  'nova-micro': '#00C49F',
  'nova-lite': '#0088FE',
  'nova-pro': '#8884D8',
  'claude-sonnet': '#FF8042',
  'gemini': '#FFBB28',
};

export const MonitoringPage: React.FC = () => {
  const [period, setPeriod] = useState('7d');

  const { data: metrics, isLoading } = useQuery({
    queryKey: ['metrics', period],
    queryFn: () => adminApi.getMetrics(period),
  });

  const { data: costBreakdown } = useQuery({
    queryKey: ['costBreakdown', period],
    queryFn: () => adminApi.getCostBreakdown(period),
  });

  const { data: errors } = useQuery({
    queryKey: ['recentErrors'],
    queryFn: () => adminApi.getRecentErrors(),
  });

  if (isLoading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4">📊 Monitoramento</Typography>
        <FormControl size="small" sx={{ minWidth: 120 }}>
          <InputLabel>Período</InputLabel>
          <Select value={period} label="Período" onChange={(e) => setPeriod(e.target.value)}>
            <MenuItem value="24h">Últimas 24h</MenuItem>
            <MenuItem value="7d">Últimos 7 dias</MenuItem>
            <MenuItem value="30d">Últimos 30 dias</MenuItem>
            <MenuItem value="90d">Últimos 90 dias</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {/* Cards de Estatísticas */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatsCard
            title="Custo Total (LLM)"
            value={`$${metrics?.totalCost?.toFixed(2) || '0.00'}`}
            change={metrics?.costChange || 0}
            icon={<AttachMoney />}
            color="#6750A4"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatsCard
            title="Conversas"
            value={metrics?.totalConversations || 0}
            change={metrics?.conversationsChange || 0}
            icon={<Chat />}
            color="#00C49F"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatsCard
            title="Latência Média"
            value={`${metrics?.avgLatency || 0}ms`}
            change={metrics?.latencyChange || 0}
            icon={<Speed />}
            color="#0088FE"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatsCard
            title="Taxa de Erro"
            value={`${metrics?.errorRate?.toFixed(2) || '0'}%`}
            change={metrics?.errorRateChange || 0}
            icon={<ErrorIcon />}
            color="#FF8042"
          />
        </Grid>
      </Grid>

      {/* Gráficos */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {/* Custo por Dia */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Custo Diário por Modelo
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={metrics?.dailyCosts || []}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip formatter={(value: number) => [`$${value.toFixed(4)}`, '']} />
                  <Bar dataKey="nova-micro" stackId="a" fill={MODEL_COLORS['nova-micro']} />
                  <Bar dataKey="nova-lite" stackId="a" fill={MODEL_COLORS['nova-lite']} />
                  <Bar dataKey="nova-pro" stackId="a" fill={MODEL_COLORS['nova-pro']} />
                  <Bar dataKey="claude-sonnet" stackId="a" fill={MODEL_COLORS['claude-sonnet']} />
                  <Bar dataKey="gemini" stackId="a" fill={MODEL_COLORS['gemini']} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* Distribuição de Custos */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Custo por Modelo
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={costBreakdown || []}
                    dataKey="cost"
                    nameKey="model"
                    cx="50%"
                    cy="50%"
                    outerRadius={80}
                    label={({ name, percent }) => `${name} (${(percent * 100).toFixed(1)}%)`}
                  >
                    {(costBreakdown || []).map((entry: any, index: number) => (
                      <Cell key={index} fill={MODEL_COLORS[entry.model] || '#8884D8'} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: number) => [`$${value.toFixed(4)}`, 'Custo']} />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabela de Erros Recentes */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🚨 Erros Recentes
          </Typography>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Timestamp</TableCell>
                <TableCell>Agente</TableCell>
                <TableCell>Erro</TableCell>
                <TableCell>User ID</TableCell>
                <TableCell>Trip ID</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(errors || []).slice(0, 10).map((error: any, index: number) => (
                <TableRow key={index}>
                  <TableCell>
                    {format(new Date(error.timestamp), 'dd/MM HH:mm:ss')}
                  </TableCell>
                  <TableCell>
                    <Chip label={error.agent} size="small" />
                  </TableCell>
                  <TableCell sx={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {error.message}
                  </TableCell>
                  <TableCell sx={{ fontFamily: 'monospace', fontSize: 12 }}>
                    {error.user_id?.slice(0, 8)}...
                  </TableCell>
                  <TableCell sx={{ fontFamily: 'monospace', fontSize: 12 }}>
                    {error.trip_id?.slice(0, 8)}...
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Box>
  );
};
```

### Passo 4.13: Gestão de Usuários

Visualizar e gerenciar usuários e suas viagens.

**src/pages/Users.tsx**:

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  Card,
  CardContent,
  Tabs,
  Tab,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Chip,
  IconButton,
  Tooltip,
} from '@mui/material';
import { DataGrid, GridColDef, GridRenderCellParams } from '@mui/x-data-grid';
import {
  Search,
  Block,
  CheckCircle,
  Flight,
  Chat,
  Visibility,
  Download,
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '../services/adminApi';
import { format } from 'date-fns';

export const UsersPage: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const queryClient = useQueryClient();

  const { data: users = [], isLoading } = useQuery({
    queryKey: ['users', searchTerm],
    queryFn: () => adminApi.searchUsers(searchTerm),
  });

  const { data: userDetails } = useQuery({
    queryKey: ['userDetails', selectedUser?.user_id],
    queryFn: () => adminApi.getUserDetails(selectedUser?.user_id),
    enabled: !!selectedUser,
  });

  const toggleStatusMutation = useMutation({
    mutationFn: (userId: string) => adminApi.toggleUserStatus(userId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });

  const columns: GridColDef[] = [
    {
      field: 'email',
      headerName: 'Email',
      flex: 1,
      renderCell: (params: GridRenderCellParams) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Avatar sx={{ width: 32, height: 32, fontSize: 14 }}>
            {params.row.name?.[0] || params.row.email[0]}
          </Avatar>
          <Box>
            <Typography variant="body2">{params.row.email}</Typography>
            <Typography variant="caption" color="text.secondary">
              {params.row.name}
            </Typography>
          </Box>
        </Box>
      ),
    },
    {
      field: 'trips_count',
      headerName: 'Viagens',
      width: 100,
      renderCell: (params: GridRenderCellParams) => (
        <Chip
          icon={<Flight />}
          label={params.value}
          size="small"
          color="primary"
          variant="outlined"
        />
      ),
    },
    {
      field: 'messages_count',
      headerName: 'Mensagens',
      width: 110,
      renderCell: (params: GridRenderCellParams) => (
        <Chip
          icon={<Chat />}
          label={params.value}
          size="small"
          variant="outlined"
        />
      ),
    },
    {
      field: 'last_active',
      headerName: 'Último Acesso',
      width: 150,
      valueFormatter: (params) =>
        params.value ? format(new Date(params.value), 'dd/MM/yyyy HH:mm') : '-',
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 100,
      renderCell: (params: GridRenderCellParams) => (
        <Chip
          label={params.value === 'active' ? 'Ativo' : 'Bloqueado'}
          color={params.value === 'active' ? 'success' : 'error'}
          size="small"
        />
      ),
    },
    {
      field: 'actions',
      headerName: 'Ações',
      width: 120,
      renderCell: (params: GridRenderCellParams) => (
        <Box>
          <Tooltip title="Ver Detalhes">
            <IconButton size="small" onClick={() => setSelectedUser(params.row)}>
              <Visibility />
            </IconButton>
          </Tooltip>
          <Tooltip title={params.row.status === 'active' ? 'Bloquear' : 'Desbloquear'}>
            <IconButton
              size="small"
              onClick={() => toggleStatusMutation.mutate(params.row.user_id)}
            >
              {params.row.status === 'active' ? <Block /> : <CheckCircle />}
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        👥 Usuários
      </Typography>

      {/* Busca */}
      <TextField
        fullWidth
        placeholder="Buscar por email ou nome..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <Search />
            </InputAdornment>
          ),
        }}
        sx={{ mb: 3 }}
      />

      {/* Tabela de Usuários */}
      <Card>
        <CardContent>
          <DataGrid
            rows={users}
            columns={columns}
            loading={isLoading}
            getRowId={(row) => row.user_id}
            pageSizeOptions={[10, 25, 50]}
            initialState={{
              pagination: { paginationModel: { pageSize: 10 } },
            }}
            autoHeight
            disableRowSelectionOnClick
          />
        </CardContent>
      </Card>

      {/* Dialog de Detalhes do Usuário */}
      <Dialog
        open={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar sx={{ width: 48, height: 48 }}>
              {selectedUser?.name?.[0] || selectedUser?.email?.[0]}
            </Avatar>
            <Box>
              <Typography variant="h6">{selectedUser?.name || selectedUser?.email}</Typography>
              <Typography variant="body2" color="text.secondary">
                {selectedUser?.email}
              </Typography>
            </Box>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Tabs value={0}>
            <Tab label="Viagens" />
            <Tab label="Histórico de Chat" />
            <Tab label="Auditoria" />
          </Tabs>

          {/* Lista de Viagens */}
          <List>
            {userDetails?.trips?.map((trip: any) => (
              <ListItem key={trip.trip_id} divider>
                <ListItemAvatar>
                  <Avatar sx={{ bgcolor: 'primary.light' }}>
                    <Flight />
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={trip.name}
                  secondary={
                    <>
                      {trip.destination} • {trip.dates}
                      <br />
                      <Chip label={trip.status} size="small" sx={{ mt: 0.5 }} />
                    </>
                  }
                />
              </ListItem>
            ))}
          </List>

          <Box sx={{ mt: 2, display: 'flex', gap: 2 }}>
            <Button variant="outlined" startIcon={<Download />}>
              Exportar Dados (LGPD)
            </Button>
          </Box>
        </DialogContent>
      </Dialog>
    </Box>
  );
};
```

### Passo 4.14: API Admin

Serviço para comunicação com o backend administrativo.

**src/services/adminApi.ts**:

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_ADMIN_API_URL || 'https://admin.n-agent.com/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para adicionar token de autenticação
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('adminToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const adminApi = {
  // Prompts
  getPromptConfig: async (agentType: string) => {
    const { data } = await api.get(`/prompts/${agentType}`);
    return data;
  },

  savePrompt: async (agentType: string, content: string, changeSummary: string) => {
    const { data } = await api.post(`/prompts/${agentType}/versions`, {
      content,
      change_summary: changeSummary,
    });
    return data;
  },

  testPrompt: async (agentType: string, promptContent: string, input: string) => {
    const { data } = await api.post(`/prompts/${agentType}/test`, {
      prompt_content: promptContent,
      test_input: input,
    });
    return data;
  },

  activatePromptVersion: async (agentType: string, version: number) => {
    const { data } = await api.put(`/prompts/${agentType}/active`, { version });
    return data;
  },

  // Integrações
  getIntegrations: async () => {
    const { data } = await api.get('/integrations');
    return data;
  },

  updateIntegration: async (id: string, config: Record<string, string>) => {
    const { data } = await api.put(`/integrations/${id}`, config);
    return data;
  },

  testIntegration: async (id: string) => {
    const { data } = await api.post(`/integrations/${id}/test`);
    return data;
  },

  // Métricas
  getMetrics: async (period: string) => {
    const { data } = await api.get('/metrics', { params: { period } });
    return data;
  },

  getCostBreakdown: async (period: string) => {
    const { data } = await api.get('/metrics/costs', { params: { period } });
    return data;
  },

  getRecentErrors: async () => {
    const { data } = await api.get('/metrics/errors');
    return data;
  },

  // Usuários
  searchUsers: async (query: string) => {
    const { data } = await api.get('/users', { params: { q: query } });
    return data;
  },

  getUserDetails: async (userId: string) => {
    const { data } = await api.get(`/users/${userId}`);
    return data;
  },

  toggleUserStatus: async (userId: string) => {
    const { data } = await api.post(`/users/${userId}/toggle-status`);
    return data;
  },

  exportUserData: async (userId: string) => {
    const { data } = await api.get(`/users/${userId}/export`);
    return data;
  },

  // Auditoria
  getAuditLogs: async (filters: Record<string, any>) => {
    const { data } = await api.get('/audit', { params: filters });
    return data;
  },
};
```

### Passo 4.15: Roteamento do Admin Panel

**src/App.tsx**:

```typescript
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, CssBaseline } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AdminLayout } from './components/common/AdminLayout';
import { Dashboard } from './pages/Dashboard';
import { PromptManager } from './pages/PromptManager';
import { IntegrationsPage } from './pages/Integrations';
import { UsersPage } from './pages/Users';
import { MonitoringPage } from './pages/Monitoring';
import { AuditLogPage } from './pages/AuditLog';
import { LoginPage } from './pages/Login';
import { useAdminAuth } from './hooks/useAdminAuth';
import { adminTheme } from './theme';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30000,
      retry: 1,
    },
  },
});

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, isAdmin } = useAdminAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (!isAdmin) {
    return <Navigate to="/unauthorized" replace />;
  }
  
  return <>{children}</>;
};

const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={adminTheme}>
        <CssBaseline />
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <AdminLayout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="prompts" element={<PromptManager />} />
              <Route path="integrations" element={<IntegrationsPage />} />
              <Route path="users" element={<UsersPage />} />
              <Route path="monitoring" element={<MonitoringPage />} />
              <Route path="audit" element={<AuditLogPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

export default App;
```

### Passo 4.16: Backend Admin (Lambda)

Criar Lambda para servir as APIs administrativas:

**lambdas/admin-api/src/handlers/prompts.ts**:

```typescript
import { APIGatewayProxyHandler } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuid } from 'uuid';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.CONFIG_TABLE || 'n-agent-config';

export const getPromptConfig: APIGatewayProxyHandler = async (event) => {
  const agentType = event.pathParameters?.agentType;
  
  // Buscar configuração atual
  const { Item } = await docClient.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: `PROMPT#${agentType}`, SK: 'CONFIG' }
  }));
  
  // Buscar versões
  const { Items: versions } = await docClient.send(new QueryCommand({
    TableName: TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
    ExpressionAttributeValues: {
      ':pk': `PROMPT#${agentType}`,
      ':sk': 'VERSION#'
    },
    ScanIndexForward: false
  }));
  
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      ...Item,
      versions: versions || []
    })
  };
};

export const savePromptVersion: APIGatewayProxyHandler = async (event) => {
  const agentType = event.pathParameters?.agentType;
  const { content, change_summary } = JSON.parse(event.body || '{}');
  const userId = event.requestContext.authorizer?.claims?.sub;
  
  // Obter versão atual
  const { Item: config } = await docClient.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: `PROMPT#${agentType}`, SK: 'CONFIG' }
  }));
  
  const newVersion = (config?.active_version || 0) + 1;
  const now = new Date().toISOString();
  
  // Salvar nova versão
  await docClient.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `PROMPT#${agentType}`,
      SK: `VERSION#${String(newVersion).padStart(5, '0')}`,
      version: newVersion,
      content,
      change_summary,
      created_at: now,
      created_by: userId,
      is_active: false
    }
  }));
  
  return {
    statusCode: 201,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      version: newVersion,
      message: 'Versão criada com sucesso. Ative-a para usar em produção.'
    })
  };
};

export const activateVersion: APIGatewayProxyHandler = async (event) => {
  const agentType = event.pathParameters?.agentType;
  const { version } = JSON.parse(event.body || '{}');
  
  // Atualizar config para nova versão ativa
  await docClient.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `PROMPT#${agentType}`,
      SK: 'CONFIG',
      active_version: version,
      updated_at: new Date().toISOString()
    }
  }));
  
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: `Versão ${version} ativada com sucesso.` })
  };
};
```

---

## Checklist de Conclusão da Fase 4

### Web Client
- [ ] Projeto React criado com Vite
- [ ] Tema Material UI M3 configurado
- [ ] Autenticação Cognito funcionando
- [ ] Login/Signup funcionando
- [ ] Dashboard listando viagens
- [ ] Página de detalhes da viagem
- [ ] Chat integrado com o agente
- [ ] Rich Cards renderizando corretamente
- [ ] Deploy no CloudFront/S3

### Admin Panel
- [ ] Projeto React admin-panel criado
- [ ] Autenticação admin (grupos Cognito)
- [ ] Gestão de Prompts com editor Monaco
- [ ] Versionamento de prompts funcionando
- [ ] Teste de prompts integrado
- [ ] Configuração de integrações (API keys)
- [ ] Dashboard de métricas e custos
- [ ] Gráficos de uso por modelo
- [ ] Tabela de erros recentes
- [ ] Gestão de usuários (busca, bloqueio)
- [ ] Exportação de dados (LGPD)
- [ ] Logs de auditoria
- [ ] Lambda admin-api criada
- [ ] Deploy no CloudFront/S3 (subdomínio admin)

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
