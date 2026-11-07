---
name: feature-creator
description: "Trigger: crear feature, nueva feature, create feature, new feature, feature structure, feature scaffold, estructura de feature. Guide for creating features in React dashboard projects based on the react-template conventions (zod DTOs, read models in domain, HttpBase-wrapping services, feature public API, useListPage lists, Zod forms)."
license: Apache-2.0
metadata:
  author: "CarlJSL"
  version: "1.4"
---

## Activation Contract

Create or scaffold a feature when the user:
- asks for a new feature, module, or screen
- mentions feature structure, folders, or conventions
- extends an existing feature with new screens or endpoints

Do NOT use for:
- One-off components outside a feature (generic pieces go in `src/shared/`)
- Domain models or enums alone (they live in `src/domain/`)

Before writing code, in the target project: copy `src/features/_base/` (unrouted skeleton) and read `src/features/products/` (complete reference). If the project's layout differs from this skill, follow the project.

## Template contract

Verified against the react-template `chore/base-template` branch (`docs/contracts.md`, `docs/architecture-boundaries.md`, `docs/session-and-access.md`, `docs/example-products.md`, `docs/tooling.md`, `src/features/products`).

**Stable (apply always):**
- Three shapes per feature: API DTO, read model, form model, converted by named mappers
- Response DTOs are zod schemas; services validate at the boundary and return read models
- Layers `domain <- core <- components/ui <- shared <- features <- app`; each feature exposes only `index.ts`
- Centralized query keys, `useListPage`, `ListPageLayout`, `FormFooter`, `ICombo`
- Quality gate `pnpm check`

**Still expected to change (verify in the project):**
- Backend contracts are unverified; schemas follow what the original client read (`docs/contracts.md`, "Unverified contracts")
- `_base` keeps its read model in `models/feature.model.ts` as a skeleton; in a real feature it moves to `src/domain/models/`
- The `products` example is development-only and is deleted in real projects
- Role codes, the `Permission` list and the `ROUTE_ACCESS` defaults are neutral placeholders

## The three shapes

| Shape | Location | Used by |
| --- | --- | --- |
| API DTO (wire) | `src/features/<x>/api/<x>.dto.ts` | Only `api/` (service, mappers) |
| Read model | `src/domain/models/<x>.ts` | Hooks, tables, modals |
| Form model | `src/features/<x>/forms/<x>.schema.ts` | Form component and `mappers/` |

Flow: service -> `parseResponse(dtoSchema)` -> `api/mappers/` `to<X>(dto)` -> read model -> `mappers/` `map<X>ToFormValues` -> form -> `mappers/` `map<X>FormToRequest` -> request DTO -> service.

## Hard Rules

1. **No hook or component reads a DTO.** Services return read models (`Page<T>`, `ActionResult`, `ICombo | null`, entity read models). A form never submits its values as the body: a mapper builds the request DTO.
2. **DTOs live in the feature** (`api/<x>.dto.ts`): response schemas `<x>DtoSchema` with `type <X>Dto = z.output<typeof ...>`; request bodies are plain types `<X>RequestDto`. No transforms in DTO schemas. Unknown keys are dropped.
3. **Schema strictness:** required for ids and fields the UI uses without a fallback; `.nullish()` for fields the UI already renders with a fallback; ids that may be text or number use `flexibleIdSchema` (`@/core/lib/api-contracts`) and become strings via `toId`.
4. **Read models live in `src/domain/models/<x>.ts`**, exported from the barrel `src/domain/models/index.ts`. Domain is a leaf: plain types and classes, no zod, no imports from core or features. Filter request classes (`<X>Filtro extends BaseFiltro`) live next to the read model.
5. **Enums live in `src/domain/enums/`** as `as const` objects plus a derived `...Type` union. **ALWAYS export a new enum from `src/domain/enums/index.ts`.**
6. **Services wrap `HttpBase`**, they do not extend it. Constructor: `new HttpBase<EntityDto, FilterModel, InitDto, InitFormDto>(baseUrl, { entity, init?, initForm? })`. Export a plain `<x>Service` object. Never export the `HttpBase` instance or return its DTOs. Calling `init()` or `initForm()` without its schema throws.
7. **Validation happens at the boundary.** `HttpBase` methods that return data (`find`, `search`, `get`, `getById`, `init`, `initForm`, `saveOrUpdate`, `remove`) call `parseResponse`. `create`, `update` and `saveOrUpdateWithFile` ignore the response body and do not validate it. Custom endpoints use `api.*` plus `parseResponse(schema, response)`. An invalid body becomes an `ApiError` with code `INVALID_RESPONSE` (`INVALID_RESPONSE_CODE`).
8. **Two mapper folders:** `api/mappers/` is DTO to read model (`to<X>`); `mappers/` is the UI side (`map<X>ListaToFiltro`, `map<X>FormToRequest`, `map<X>ToFormValues`, visuals, field errors). Every conversion is one named function with a unit test.
9. **Query keys are centralized** in `api/<x>.query-keys.ts`. Never string literals like `['x', 'lista']`.
10. **Forms use Zod schemas**; types come from `z.infer` (or `z.input` / `z.output` when the schema transforms). No duplicated rules.
11. **`FormFooter`** from `@/shared/components/form/form-footer` for modal form buttons.
12. **`useListPage`** from `@/shared/hooks/useListPage` for list screens (never `useForm` for pagination) and **`ListPageLayout`** from `@/shared/components/layout/list-page-layout` for the page frame.
13. **Public API only.** Code outside a feature imports `@/features/<x>` (its `index.ts`), never a file inside it. Lint (`import-x/no-restricted-paths`, `import-x/no-cycle`) fails the build otherwise. A feature never imports `src/app`; if `shared` needs feature code, inject it from `app` through props.
14. **Routes are lazy through the entry** and every protected route has an entry in `src/domain/roles/route-access.ts`.
15. **`useCan` / `<Can>` are UX only.** They hide controls; the backend must authorize every request.
16. **Sessions end only through `endSession(reason)`** (`@/features/auth`). Never clear tokens or the auth store by hand.
17. **`import type` is ONLY for type annotations.** If you need the value at runtime (`new ProductFiltro()`, enum lookup), use a regular import.
18. **`ICombo`** from `@/domain/models` for backend option lists; build it with `toCombo`. Never create custom combo types.

## Feature Structure

```
src/features/<x>/
├── index.ts                     # public API: lazy pages + what others need
├── api/
│   ├── <x>.dto.ts               # zod response schemas, request DTO types
│   ├── <x>.service.ts           # wraps HttpBase, returns read models
│   ├── <x>.query-keys.ts
│   └── mappers/<x>.mapper.ts    # DTO -> read model (to<X>)
├── components/                  # table columns and visual pieces
├── forms/
│   ├── <x>.schema.ts            # form zod schema
│   ├── <x>.form-types.ts        # types + default values
│   ├── <x>-form.constants.ts    # form id, limits
│   └── <x>-form.tsx             # form + footer
├── hooks/
│   ├── use<X>Lista.ts           # list logic (useListPage, modal state)
│   └── <x>-filtro-config.ts     # filter field configs
├── mappers/
│   ├── <x>.mapper.ts            # filter, form <-> request, formatting
│   ├── <x>-status-visual.ts     # enum -> StatusBadge variant and label
│   └── <x>-api-error.mapper.ts  # 422 fieldErrors -> form fields
├── modals/                      # create, edit, detail
└── pages/<x>-lista-page.tsx     # route composition (default export)
```

Reference: `src/features/products/`. Real features (`usuario`, `catalogo`, `rol`) follow the same layout where they need each piece.

## DTO and read model

```ts
// src/features/products/api/product.dto.ts
export const productDtoSchema = z.object({
  id: z.string().min(1),
  name: z.string(),
  description: z.string().nullable(),
  price: z.number().finite(),
  status: z.enum([ProductStatus.ACTIVE, ProductStatus.INACTIVE]),
  createdAt: z.iso.datetime({ offset: true }),
});
export type ProductDto = z.output<typeof productDtoSchema>;

export interface ProductRequestDto {
  name: string;
  description: string | null;
  price: number;
  status: ProductDto["status"];
}
```

```ts
// src/domain/models/product.ts (read model + filter request class)
export interface Product {
  id: string; name: string; description: string | null;
  price: number; status: ProductStatusType; createdAt: Date;
}
export class ProductFiltro extends BaseFiltro { status?: ProductStatusType; }
```

```ts
// src/features/products/api/mappers/product.mapper.ts
export function toProduct(dto: ProductDto): Product {
  return { id: dto.id, name: dto.name, description: dto.description,
    price: dto.price, status: dto.status, createdAt: new Date(dto.createdAt) };
}
```

Shared envelopes in `@/core/lib/api-contracts`: `pageDtoSchema`, `responseMessageDtoSchema`, `comboDtoSchema`, with mappers `toPage`, `toActionResult`, `toCombo`. Their read models: `Page<T>`, `ActionResult`, `ICombo` (`@/domain/models`).

## Service Pattern

```ts
// src/features/products/api/product.service.ts
const productApi = new HttpBase<ProductDto, ProductFiltro>("/products", {
  entity: productDtoSchema,
});

export const productService = {
  async find(filtro: ProductFiltro): Promise<Page<Product>> {
    return toPage(await productApi.find(filtro), toProduct);
  },
  async get(id: string): Promise<Product> {
    return toProduct(await productApi.get(id));
  },
  create(request: ProductRequestDto): Promise<void> {
    return productApi.create(request);
  },
  // Custom endpoint: api.* + parseResponse, then map
  async updateStatus(id: string, status: ProductStatusType): Promise<Product> {
    const response = await api.patch(`/products/${id}/status`, { status });
    return toProduct(parseResponse(productDtoSchema, response));
  },
};
```

- `HttpBase` generics: `<EntityDto, FilterModel = Partial<EntityDto>, InitDto = Partial<EntityDto>, InitFormDto = InitDto>`. Omit trailing generics only when the defaults fit.
- **`get(id)`** (`/get/{id}`) feeds EDIT forms; **`getById(id)`** (`/getById/{id}`) feeds VIEW/detail. `find` and `search` both POST and return a page DTO; use `find`.
- Write endpoints: `saveOrUpdate` and `remove` go through `toActionResult` and return `ActionResult`; `create` and `update` return `void`.
- Add a custom method when the endpoint is not standard CRUD, or a file upload needs more than `saveOrUpdateWithFile`.
- Pass `{ silent: true }` in the Axios config only when the caller shows its own feedback; read errors with `getApiError(error)` from `@/core/lib/interceptor/api-error.mapper`. `silent` does not change session handling.

## Query Keys Pattern

```ts
// src/features/products/api/product.query-keys.ts
export const productKeys = {
  all: ["product"] as const,
  list: () => [...productKeys.all, "lista"] as const,
  get: (id: string) => [...productKeys.all, "get", id] as const,
  detail: (id: string) => [...productKeys.all, "detalle", id] as const,
};
```

`_base` also declares `init` and `initForm` keys for features that load options. After a mutation, `invalidateQueries({ queryKey: productKeys.all })`.

## Mapper Pattern (`mappers/`)

```ts
// src/features/products/mappers/product.mapper.ts
export type ProductListaFiltros = { status?: string };   // UI filter state

export function mapProductListaToFiltro(
  page: number, limit: number, search: string, filtros?: ProductListaFiltros,
): ProductFiltro {
  const filtro = new ProductFiltro();
  filtro.start = page - 1;                                // zero-based page index
  filtro.limit = limit;
  const keyword = search.trim();
  if (keyword) filtro.palabraClave = keyword;
  if (isProductStatus(filtros?.status)) filtro.status = filtros.status;
  return filtro;
}

export function mapProductFormToRequest(data: ProductFormOutput): ProductRequestDto { /* trim, "" -> null */ }
export function mapProductToFormValues(product: Product): ProductFormValues { /* price.toFixed(2) */ }
```

Filter field ids in `FilterFieldConfig` must match the keys the mapper reads. Edit mappers take the record id as a parameter (`mapFeatureEditFormToRequest(data, featureId)` in `_base`).

## Form Pattern

```ts
// forms/product.schema.ts: one schema for create and edit (_base uses separate ones)
export const productSchema = z.object({
  name: z.string().trim().min(2, "Mínimo 2 caracteres").max(100, "Máximo 100 caracteres"),
  price: z.string().trim().min(1, { error: "Requerido", abort: true })
    .regex(PRICE_PATTERN, "Ingrese un monto con hasta 2 decimales")
    .transform(Number).refine((value) => value > 0, "Debe ser mayor a 0"),
  // ...
});
export type ProductFormValues = z.input<typeof productSchema>;   // what the inputs hold
export type ProductFormOutput = z.output<typeof productSchema>;  // after validation
```

- `forms/<x>.form-types.ts` re-exports the types and defines `<x>DefaultValues`.
- With a transforming schema: `useForm<ProductFormValues, unknown, ProductFormOutput>({ resolver: zodResolver(productSchema), defaultValues })`.
- Submit with `saveMutation.mutate(mapProductFormToRequest(data))`; the mutation takes the request DTO.
- On success: invalidate `productKeys.all`, show the success modal, close. On 422: `mapProductValidationError(error)` returns `{ field, message }[]` restricted to the form fields; call `setError(field, { type: "server", message })`.
- Footer: `<FormFooter formId submitLabel submittingLabel onCancel isSubmitting isDirty />`, with the id from `<x>-form.constants.ts`.

## List Hook and Page

```ts
const list = useListPage<Product, ProductListaFiltros>({
  queryKey: productKeys.list(),             // required; page, limit, search, filters are appended
  fetchData: async (page, limit, search, filtros) => {
    const response = await productService.find(mapProductListaToFiltro(page, limit, search, filtros));
    return { elements: response.elements, total: response.totalCount };
  },
});
```

`useListPage` returns `elements`, `isLoading`, `isError`, `pagination`, `itemsPerPage`, `searchQuery`, `filtros`, `activeFilterCount`, `setValue`, `handleLimitChange`, `handleSearch`, `handleFilterApply`, `handleFilterClear`, `refetch`.

The page composes `ListPageLayout` (`breadcrumb`, `title`, `toolbar`, `isLoading`, `isError`, `pagination`, `modals`, table as `children`) with `DataToolbar`, `FiltroDrawer`, `DataTable` and `DataPagination` from `@/shared/components/table/`. Keep logic in `use<X>Lista`; see `pages/product-lista-page.tsx`.

**Filter config** (`FilterFieldConfig` from `@/shared/types/filter.types`, options `{ label, value }`) receives data and never fetches. Enum filters map `Object.values(ProductStatus)`; backend options map `ICombo` items (`item.nombre`, `item.codigo`).

## Enums and Visual Mapper

```ts
// src/domain/enums/product-status.ts, then export it from src/domain/enums/index.ts
export const ProductStatus = { ACTIVE: "ACTIVE", INACTIVE: "INACTIVE" } as const;
export type ProductStatusType = (typeof ProductStatus)[keyof typeof ProductStatus];
```

Use enum members as keys, never hardcoded codes. Each enum shown in a table needs a visual mapper in `mappers/`:

```ts
// mappers/product-status-visual.ts
export const productStatusVisual: Record<string, StatusVariant> = {
  [ProductStatus.ACTIVE]: "active",
  [ProductStatus.INACTIVE]: "inactive",
};
export const productStatusLabel: Record<ProductStatusType, string> = { /* Activo, Inactivo */ };
// column cell: <StatusBadge variant={productStatusVisual[s] ?? "default"} estado={productStatusLabel[s] ?? s} />
```

`StatusBadge` and `StatusVariant` come from `@/shared/components/wrapper/status-badge`.

## Public API, Routes and Access

```ts
// src/features/usuario/index.ts: lazy pages keep one chunk per page
export const UsuarioListaPage = lazy(() => import("./pages/usuario-lista"));
```

Export only what other code needs (pages, components, hooks, services, types). Another feature is reached only through its `index.ts`.

To add a protected route:
1. Add it to `AppRoute` and `ROUTE_ACCESS` in `src/domain/roles/route-access.ts` (`ALL_ROLES` or a role list).
2. Map it to its page in `PROTECTED_PAGES` (`src/app/protected-pages.ts`); the type fails to compile when a route has no page.
3. The sidebar drops backend menu links that are outside `ROUTE_ACCESS`, so the route must be registered for its link to show.

Action-level checks: add a key to `Permission` and `PERMISSION_ROLES` (`src/domain/roles/permissions.ts`), then use `useCan(Permission.X)` (`@/shared/hooks/useCan`) or `<Can permission fallback>` (`@/shared/components/can`). Example: `useUsuarioLista`.

Mocks exist only in development (MSW in `src/mocks`, flag `VITE_MOCK_SERVICES`); a production build that includes mock code fails. `products` is dev-only for that reason: real features are never behind that gate.

## Tests

- Unit-test every mapper (nulls, empty strings, dates, enums, combos) and the form schema (missing field, wrong type).
- For a new resource add a contract test through the real pipeline: a valid payload becomes a read model; an invalid one rejects with `INVALID_RESPONSE` (see `src/features/products/api/product.contract.test.ts`: `server.use(...createHandlers({ baseUrl, store }))` and a `configureHttpNotifier` spy).
- List new contracts as unverified in `docs/contracts.md` until the backend confirms them.

## How to verify

Run `pnpm check` in the target project: `format:check`, `typecheck`, `lint`, `test`, `build`, stopping at the first failure. Lint enforces the layer and public-API boundaries, so a forbidden import fails there. `pnpm format` fixes Prettier issues (printWidth 100).

## Checklist Before Done

- [ ] Copied `_base`, compared with `products`, checked the project layout
- [ ] DTO schema in `api/<x>.dto.ts` (required vs `.nullish()`); request DTOs are plain types
- [ ] Read model and `<X>Filtro` in `src/domain/models/<x>.ts`, exported from the barrel
- [ ] Enums in `src/domain/enums/` AND exported from `index.ts`; visual mapper for enums shown in tables
- [ ] Service wraps `HttpBase` with schemas, returns read models only, no DTO reaches hooks
- [ ] `to<X>` in `api/mappers/`; filter, form-to-request and read-model-to-form mappers in `mappers/`; all unit-tested
- [ ] Query keys centralized, no string literals
- [ ] Zod form schema, inferred types, `form-types.ts` with defaults, 422 field errors mapped
- [ ] `FormFooter` for modal forms; `useListPage` with `queryKey`; `ListPageLayout` for the page
- [ ] `ICombo` for option lists
- [ ] `index.ts` with lazy pages; no cross-feature internal imports
- [ ] Route in `AppRoute`, `ROUTE_ACCESS` and `PROTECTED_PAGES`; role-restricted actions behind `useCan` / `<Can>`
- [ ] `import type` only for type annotations
- [ ] `pnpm check` passes

## References

Paths in the target project (react-template, `chore/base-template`):

- `docs/contracts.md`: three shapes, validation policy, add-an-endpoint steps
- `docs/architecture-boundaries.md`: layers, public API rule, lint configuration
- `docs/session-and-access.md`: `endSession`, errors, silent requests, route access, `useCan`
- `docs/example-products.md`: products walkthrough, mapping to `_base`
- `docs/tooling.md`: `pnpm check`, formatting, lint rules
- `src/features/_base/`: unrouted skeleton (`api/feature.dto.ts`, `api/feature.service.ts`, `api/mappers/feature.mapper.ts`, `forms/`, `mappers/feature.mapper.ts`)
- `src/features/products/`: complete reference implementation
- `src/core/lib/http-base.ts`, `src/core/lib/response-validation.ts`, `src/core/lib/api-contracts.ts`
- `src/domain/roles/route-access.ts`, `src/domain/roles/permissions.ts`
- `src/shared/hooks/useListPage.ts`, `src/shared/hooks/useCan.ts`
- `src/shared/components/layout/list-page-layout.tsx`, `src/shared/components/form/form-footer.tsx`, `src/shared/components/can.tsx`
- `src/shared/components/wrapper/status-badge.tsx`, `src/shared/types/filter.types.ts`
- `eslint.config.js`: boundary zones
