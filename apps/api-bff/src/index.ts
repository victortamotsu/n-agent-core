import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'n-agent-bff', timestamp: new Date().toISOString() });
});

// API routes placeholder
app.get('/api/v1/trips', (_req: Request, res: Response) => {
  res.json({ message: 'Trips endpoint - Coming soon' });
});

app.listen(PORT, () => {
  console.log(`🚀 BFF Server running on http://localhost:${PORT}`);
});
