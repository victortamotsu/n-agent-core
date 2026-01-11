/**
 * Chat Page
 * 
 * Main chat interface (placeholder for Week 4)
 */

import { Box, Container, Typography, Button } from '@mui/material';
import { signOut } from 'aws-amplify/auth';
import { useNavigate } from 'react-router-dom';

export default function Chat() {
  const navigate = useNavigate();

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };

  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
          <Typography variant="h4" component="h1">
            n-agent Chat
          </Typography>
          <Button variant="outlined" onClick={handleSignOut}>
            Sair
          </Button>
        </Box>
        
        <Typography variant="body1" color="text.secondary">
          Interface de chat será implementada na Semana 4
        </Typography>
      </Box>
    </Container>
  );
}
