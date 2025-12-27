import { Container, Typography, Box, Button } from '@mui/material';
import FlightTakeoffIcon from '@mui/icons-material/FlightTakeoff';

function HomePage() {
  return (
    <Container maxWidth="lg">
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          textAlign: 'center',
        }}
      >
        <FlightTakeoffIcon sx={{ fontSize: 80, color: 'primary.main', mb: 2 }} />
        <Typography variant="h2" component="h1" gutterBottom>
          n-agent
        </Typography>
        <Typography variant="h5" color="text.secondary" paragraph>
          Seu assistente pessoal de viagens
        </Typography>
        <Typography variant="body1" color="text.secondary" paragraph sx={{ maxWidth: 600 }}>
          Organize suas viagens de forma inteligente com nosso agente de IA. Da fase de
          planejamento até as memórias da viagem.
        </Typography>
        <Box sx={{ mt: 4 }}>
          <Button variant="contained" size="large" sx={{ mr: 2 }}>
            Começar Agora
          </Button>
          <Button variant="outlined" size="large">
            Saber Mais
          </Button>
        </Box>
      </Box>
    </Container>
  );
}

export default HomePage;
