const esbuild = require('esbuild');
const path = require('path');
const fs = require('fs');

// Plugin to resolve monorepo packages
const monorepoPlugin = {
  name: 'monorepo',
  setup(build) {
    build.onResolve({ filter: /^@n-agent\// }, (args) => {
      const packageName = args.path.split('/')[1]; // Get package name after @n-agent/
      const packagePath = path.join(__dirname, '../packages', packageName, 'src', 'index.ts');
      
      if (fs.existsSync(packagePath)) {
        return { path: packagePath };
      }
      
      return null;
    });
  },
};

const services = ['whatsapp-bot', 'trip-planner', 'integrations', 'auth', 'authorizer'];

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
      plugins: [monorepoPlugin],
    });
    
    console.log(`✓ ${service} bundled successfully`);
  }
}

buildAll().catch((err) => {
  console.error(err);
  process.exit(1);
});
