/**
 * Login Component
 * 
 * Material Design 3 styled login page with OAuth providers
 */

import { Box, Button, Container, Paper, Stack, Typography } from '@mui/material';
import GoogleIcon from '@mui/icons-material/Google';
import MicrosoftIcon from '@mui/icons-material/Microsoft';
import { signInWithRedirect } from 'aws-amplify/auth';
import { useState } from 'react';

export default function Login() {
  const [loading, setLoading] = useState<string | null>(null);

  const handleGoogleLogin = async () => {
    try {
      setLoading('google');
      await signInWithRedirect({ provider: 'Google' });
    } catch (error) {
      console.error('Google login error:', error);
      setLoading(null);
    }
  };

  const handleMicrosoftLogin = async () => {
    try {
      setLoading('microsoft');
      await signInWithRedirect({ provider: 'Microsoft' });
    } catch (error) {
      console.error('Microsoft login error:', error);
      setLoading(null);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Paper
          elevation={3}
          sx={{
            p: 4,
            width: '100%',
            borderRadius: 3,
          }}
        >
          <Stack spacing={3}>
            <Box textAlign="center">
              <Typography variant="h4" component="h1" gutterBottom fontWeight={600}>
                n-agent
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Seu assistente inteligente de viagens
              </Typography>
            </Box>

            <Stack spacing={2} mt={2}>
              <Button
                variant="outlined"
                size="large"
                fullWidth
                startIcon={<GoogleIcon />}
                onClick={handleGoogleLogin}
                disabled={loading !== null}
                sx={{
                  py: 1.5,
                  textTransform: 'none',
                  fontSize: '1rem',
                }}
              >
                {loading === 'google' ? 'Conectando...' : 'Continuar com Google'}
              </Button>

              <Button
                variant="outlined"
                size="large"
                fullWidth
                startIcon={<MicrosoftIcon />}
                onClick={handleMicrosoftLogin}
                disabled={loading !== null}
                sx={{
                  py: 1.5,
                  textTransform: 'none',
                  fontSize: '1rem',
                }}
              >
                {loading === 'microsoft' ? 'Conectando...' : 'Continuar com Microsoft'}
              </Button>
            </Stack>

            <Typography variant="caption" color="text.secondary" textAlign="center" mt={2}>
              Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade
            </Typography>
          </Stack>
        </Paper>
      </Box>
    </Container>
  );
}
