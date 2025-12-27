const esbuild = require('esbuild');
const path = require('path');

const services = ['whatsapp-bot', 'trip-planner', 'integrations'];

async function buildAll() {
  for (const service of services) {
    const entryFile = service === 'whatsapp-bot' ? 'webhook.ts' : 'index.ts';
    
    console.log(`Building ${service}...`);
    
    await esbuild.build({
      entryPoints: [path.join(__dirname, `../services/${service}/src/${entryFile}`)],
      bundle: true,
      platform: 'node',
      target: 'node18',
      outfile: path.join(__dirname, `../services/${service}/dist/index.js`),
      external: ['aws-sdk'], // AWS SDK is provided by Lambda runtime
      sourcemap: true,
      minify: true,
    });
    
    console.log(`✓ ${service} bundled successfully`);
  }
}

buildAll().catch((err) => {
  console.error(err);
  process.exit(1);
});
