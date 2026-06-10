# OpenAPI Generator NestJS Fastify Template

Template for the standard OpenAPI Generator flow with `typescript-nestjs-server`.

Use the wrapper script when you want a complete runnable project. It calls OpenAPI Generator and copies the input OAS into the generated output as `api/openapi.yaml`.

```sh
./openapi-generator-nestjs-fastify-template/generate.sh \
  -i tools.openapi.yaml \
  -o ./tools-api-nest \
  --name tools-api-nest
```

Then:

```sh
cd tools-api-nest
npm run init-install
npm run dev
```

Under the hood the script runs:

```sh
npx @openapitools/openapi-generator-cli generate \
  -i tools.openapi.yaml \
  -g typescript-nestjs-server \
  -o ./tools-api-nest \
  -t ./openapi-generator-nestjs-fastify-template \
  --additional-properties=npmName=tools-api-nest,npmVersion=1.0.0,nestVersion=11.0.0,tsVersion=5.9.3
```

The generated project is runnable. Operations return `501 application/problem+json` until real implementations are wired into `ApiModule.forRoot`.
