# OpenAPI Generator NestJS Fastify Template

Template voor het genereren van een startbare TypeScript API-applicatie vanuit
een OpenAPI-specificatie.

De basis is de officiële OpenAPI Generator generator
`typescript-nestjs-server`. Deze template past de gegenereerde output aan zodat
de applicatie direct draait met **NestJS op de Fastify adapter**.

## Wat Gebruiken We?

- **Generator tool:** `@openapitools/openapi-generator-cli`
- **OpenAPI Generator generator:** `typescript-nestjs-server`
- **Applicatieframework:** NestJS
- **HTTP server/runtime:** Fastify via `@nestjs/platform-fastify`
- **OpenAPI runtime:** `openapi-backend`
- **Taal:** TypeScript

De generator maakt controllers, API interfaces en model types op basis van de
OpenAPI-specificatie. De template voegt daar een startbare applicatie omheen:
bootstrap, Fastify adapter, scripts, problem-details foutafhandeling en
OpenAPI publicatie endpoints. Tijdens runtime wordt dezelfde OAS opnieuw
geladen door `openapi-backend` voor request-validatie, route matching en
optionele mock-responses.

## Waarom Niet Alleen `openapi-generator-cli generate`?

De officiële `typescript-nestjs-server` generator genereert vooral een NestJS
API-module. Dat is bruikbaar als library, maar nog geen complete applicatie die
je direct kunt starten.

Daarnaast geeft OpenAPI Generator de ruwe input-specificatie niet betrouwbaar
door aan supporting-file templates. Daardoor kan de template zelf niet altijd
correct `api/openapi.yaml` vullen.

Daarom staat er een kleine wrapper:

```text
generate.sh
```

Die doet twee dingen:

1. Roept `npx @openapitools/openapi-generator-cli generate` aan met de juiste
   generator, template en config.
2. Kopieert de input-OAS naar de gegenereerde applicatie als
   `api/openapi.yaml`.

Zo blijft het gebruik simpel en is de gegenereerde output compleet.

## Gebruik

```sh
./openapi-generator-nestjs-fastify-template/generate.sh \
  -i tools.openapi.yaml \
  -o ./tools-api \
  --name tools-api
```

Daarna:

```sh
cd tools-api
npm run init-install
npm run dev
```

De applicatie start standaard op poort `1338`. Dit kan worden overschreven met
`PORT`.

```sh
PORT=8080 npm run dev
```

### Runtime Opties

Request-validatie staat standaard aan. De gegenereerde applicatie valideert:

- route en HTTP methode;
- request media type tegen `requestBody.content`;
- path, query, header, cookie en body schemas;
- bekende JSON schema formats via `ajv-formats`.

Fouten worden teruggegeven als `application/problem+json`. Een request naar een
bestaand pad met een verkeerde methode geeft bijvoorbeeld `405` met een
`Allow` header. Een verkeerd media type geeft `415`. Schemafouten geven `400`
met AJV-details in `errors`.

Mocking kan worden aangezet zonder implementaties te schrijven:

```sh
OPENAPI_MOCK=true npm run dev
```

In mock-mode blijft request-validatie actief. Alleen geldige requests krijgen
een mock-response op basis van OpenAPI examples of response schemas.

Response-validatie is optioneel:

```sh
OPENAPI_VALIDATE_RESPONSES=true npm run dev
```

Deze mode valideert statuscodes, response bodies en response headers tegen de
OAS. Hij staat niet standaard aan omdat de gegenereerde basisapp ontbrekende
implementaties als `501` teruggeeft. Als een operation geen `501` response in de
OAS declareert, is dat in response-validatie mode terecht een contractfout
(`502`).

## Wat Genereert Dit?

De output bevat onder andere:

```text
api/openapi.yaml
api/*.ts
controllers/*.controller.ts
models/*.ts
api.module.ts
api-implementations.ts
index.ts
package.json
tsconfig.json
```

Belangrijke runtime endpoints:

- `/openapi.yaml`
- `/openapi.json`
- alle paden uit de OpenAPI-specificatie

Nog niet geimplementeerde operations geven standaard:

```http
501 application/problem+json
```

## Wat Doet De Template Wel En Niet?

Wel:

- Routes en types genereren vanuit de OpenAPI-specificatie.
- Een startbare NestJS applicatie genereren.
- NestJS laten draaien op Fastify.
- `application/problem+json` gebruiken voor fouten.
- `API-Version` header vullen vanuit `info.version`.
- OpenAPI publiceren als YAML en JSON.
- Runtime request-validatie afdwingen vanuit de OAS.
- Optioneel mock-responses leveren vanuit OpenAPI examples/schemas.
- Optioneel response bodies en headers valideren vanuit de OAS.
- Standaard 501-responses leveren voor ontbrekende implementaties.

Niet:

- Domeinlogica genereren.
- Automatisch business packages koppelen.

Implementaties moeten dus nog worden gekoppeld via `ApiModule.forRoot`.

## Onderliggend Commando

`generate.sh` voert in essentie dit uit:

```sh
npx @openapitools/openapi-generator-cli generate \
  -i tools.openapi.yaml \
  -g typescript-nestjs-server \
  -o ./tools-api \
  -t ./openapi-generator-nestjs-fastify-template \
  -c ./openapi-generator-nestjs-fastify-template/generator-config.yaml \
  --additional-properties=npmName=tools-api,npmVersion=1.0.0,nestVersion=11.0.0,tsVersion=5.9.3
```

Daarna kopieert het script:

```sh
cp tools.openapi.yaml ./tools-api/api/openapi.yaml
```

## Implementaties Koppelen

De generator maakt abstracte API classes, bijvoorbeeld `ToolsApi`. Standaard
krijgt iedere operation een 501-response. Voor echte implementaties maak je een
service die de gegenereerde API class implementeert en geef je die door aan
`ApiModule.forRoot`.

Conceptueel:

```ts
@Module({
  imports: [
    ApiModule.forRoot({
      apiImplementations: {
        toolsApi: ToolsService,
      },
    }),
  ],
})
export class AppModule {}
```

In deze template staat de default bootstrap in `index.ts`. Voor een concreet
project kan die bootstrap worden aangepast zodat de juiste implementaties worden
geregistreerd.
