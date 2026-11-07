---
name: feature-creator
description: "Trigger: crear feature, nueva feature, create feature, new feature, feature structure, feature scaffold, estructura de feature. Guide for creating features in React dashboard projects based on the react-template conventions (HttpBase services, centralized query keys, Zod forms, useListPage lists)."
license: Apache-2.0
metadata:
  author: "CarlJSL"
  version: "1.3"
---

## Activation Contract

Create or scaffold a new feature when:
- User asks to create a new feature, module, or screen
- User mentions feature structure, folders, or conventions
- Extending an existing feature with new screens or endpoints

Do NOT use for:
- One-off components outside feature scope
- Shared utilities (those go in `src/shared/`)
- Domain models alone (currently `src/domain/`; see Template conventions may change)

Before writing code, open `src/features/_base/` in the target project and copy its files: it is the canonical, unrouted reference. If the project's layout differs from this skill, follow the project.

## Template conventions may change

The template is being restructured (removal of project-specific domain code, enforced dependency boundaries between core, shared and features, shared services moving into features). Check the project before applying location rules.

**Stable (apply always):**
- Query keys centralized per feature, never string literals
- Zod schemas for forms, types via `z.infer`
- `HttpBase` with 4 generics for services
- Mappers separated: API<->domain vs form<->request vs UI filters/visuals

**Expected to change (verify in the project first):**
- Location of domain models and enums (`src/domain/models/`, `src/domain/enums/`)
- Shared services in `src/shared/services/` (may move into the owning feature)
- Import paths that cross feature boundaries

## Hard Rules

1. **Domain models live in `src/domain/models/`**, never inside features (current layout). Features import from `@/domain/models/...`. This includes types used as service generics (filter, init, init-form models).
2. **Enums live in `src/domain/enums/`** (current layout) as `as const` objects plus a derived `...Type` union. **ALWAYS export the new enum from the barrel `src/domain/enums/index.ts`.**
3. **Services extend `HttpBase`** with up to 4 generics: `<DataModel, FilterModel, SelectModel, InitFormModel>`. Omit trailing generics only when their defaults fit.
4. **Mappers convert between API response types and domain types**, or form values to request types. Never mix concerns.
5. **Query keys are centralized** in `api/{feature}.query-keys.ts`. Never use string literals like `['features', 'lista']`.
6. **Forms use Zod schemas** for validation. Types are inferred from schemas with `z.infer`. No duplicate validation rules.
7. **`FormFooter`** from `@/shared/components/form/form-footer` for all modal form buttons.
8. **`useListPage`** from `@/shared/hooks/useListPage` for all list screens. Never `useForm` for pagination.
9. **`import type`** is ONLY for type annotations. If you need the value at runtime (`new`, function call, enum lookup), use a regular `import`.
10. **`ICombo`** from `@/domain/models/base/combo` for all combobox/select data from the backend. Never create custom combo types.

## Feature Structure

```
src/features/{feature-name}/
├── api/
│   ├── {feature}.service.ts          # HTTP calls, extends HttpBase
│   ├── {feature}.query-keys.ts       # React Query keys
│   └── mappers/                      # API<->domain mappers (complex features)
├── components/                        # Visual pieces (not forms, not modals)
├── forms/
│   ├── {feature}.schema.ts           # Zod schemas (validation lives here)
│   ├── {feature}.form-types.ts       # Re-exports types + defaultValues
│   └── {feature}-form.constants.ts   # Form IDs, constants
├── hooks/
│   ├── use{Feature}Lista.ts          # List logic (uses useListPage)
│   ├── use{Feature}Form.ts           # Form mutations
│   └── {feature}-filtro-config.ts    # Filter field configs
├── mappers/
│   ├── {feature}-filtros.mapper.ts   # UI filter -> domain filter
│   ├── {feature}-tipo-visual.ts      # Enum -> StatusBadge variant
│   └── {feature}.mapper.ts           # Form <-> request conversions
├── modals/
│   ├── {Feature}CreateModal.tsx
│   ├── {Feature}EditModal.tsx
│   └── {Feature}DetailModal.tsx
└── pages/
    └── {feature}-lista-page.tsx      # Route composition (minimal logic)
```

## Domain Models Location

- **`src/domain/models/base/`** — generic, reusable: `combo.ts` (`ICombo`, `IComboItem`), `pagination.ts` (`PaginatedResponse`, `Pagination`), `response.ts`, `base-filtro.ts` (`BaseFiltro`)
- **`src/domain/models/` (root)** — one file per business entity, `{entity}.ts` with `{Entity}`, `{Entity}Filtro`, `{Entity}Init` (e.g. `product.ts`, `customer.ts`)

## HttpBase Generics

`src/core/lib/http-base.ts` declares exactly **4 generics**:

```ts
export class HttpBase<
  DataModel,                        // Main entity (find, get, save, update)
  FilterModel = Partial<DataModel>, // Body of find/search
  SelectModel = Partial<DataModel>, // Response of init() (filter dropdowns)
  InitFormModel = SelectModel,      // Response of initForm() (form dropdowns)
>
```

**`get` vs `getById`:**
- **`get(id)`** -> `DataModel` from `/get/{id}`. Used for EDITING; may include ICombos.
- **`getById(id)`** -> `DataModel` from `/getById/{id}`. Used for VIEWING.
- **`init()`** -> `SelectModel`. Filter dropdown data.
- **`initForm()`** -> `InitFormModel`. Form dropdown data.

If the view returns a different shape, add a custom method returning the view type.

**`HttpBaseWithMapper`** (`src/core/lib/http-base-with-mapper.ts`) is an alternative with generics `<DataModel, ApiResponse, FilterModel = Partial<DataModel>>`. Its constructor takes `toDomain` and `toDomainList` mapper functions and applies them to `find`, `search`, `get` and `getById`. `init()` and `initForm()` return the raw `ApiResponse`, unmapped. Use it only when every entity response needs API->domain mapping.

## Service Pattern

```ts
// src/features/{feature}/api/{feature}.service.ts
import { HttpBase } from "@/core/lib/http-base";
import type { Feature, FeatureFiltro, FeatureInit } from "@/domain/models/feature";

class FeatureService extends HttpBase<Feature, FeatureFiltro, FeatureInit> {
  constructor() {
    super("/feature"); // backend base path
  }

  // Add custom methods here when HttpBase doesn't cover the endpoint
}

export const featureService = new FeatureService();
```

**Add custom methods** when the endpoint doesn't match the CRUD pattern (e.g. `/findMine`), the response needs mapping before reaching hooks, or a file upload goes beyond `saveOrUpdateWithFile` (use `FormData`).

**`find` vs `search`:** Both POST and return `PaginatedResponse<DataModel>`. Use `find` as standard.

## Filter Pattern

Two filter types coexist:

**1. Domain filter** (`src/domain/models/{entity}.ts`) — class extending `BaseFiltro`, sent to the backend:
```ts
import { BaseFiltro } from "./base/base-filtro";

export class FeatureFiltro extends BaseFiltro {
  nombre!: string;
  estadoCodigo!: string;
}
```

**2. UI filter** (`mappers/`) — user selections in the filter drawer:
```ts
// mappers/feature-filtros.mapper.ts
export type FeatureListaFiltros = {
  nombre?: string;
  estado?: string;
};
```

**3. Mapper function** — UI filter to domain filter (`start` is page - 1, as in existing mappers):
```ts
import { FeatureFiltro } from "@/domain/models/feature";

export function mapFeatureListaToFiltro(
  page: number,
  limit: number,
  search: string,
  filtros?: FeatureListaFiltros,
): FeatureFiltro {
  const filtro = new FeatureFiltro();
  filtro.start = page - 1;
  filtro.limit = limit;

  if (search) filtro.palabraClave = search;
  if (filtros?.nombre) filtro.nombre = filtros.nombre;
  if (filtros?.estado) filtro.estadoCodigo = filtros.estado;

  return filtro;
}
```

## Mapper Locations

**`api/mappers/`** — API response <-> domain model (when the backend shape differs):
```ts
// api/mappers/feature.mapper.ts
export function mapFeatureResponseToDomain(res: FeatureResponse): Feature {
  return { id: res.id, nombre: res.nombre, estadoCodigo: res.estado?.codigo ?? "" };
}
```

**`mappers/` (root)** — filters, colors, UI transformations, form <-> request:
```ts
// mappers/feature.mapper.ts
export function mapFeatureCreateFormToRequest(data: FeatureCreateFormValues) {
  return { nombre: data.nombre, estadoCodigo: data.estadoCodigo };
}
```

## Query Keys Pattern

```ts
// src/features/{feature}/api/{feature}.query-keys.ts
export const featureKeys = {
  all: ["feature"] as const,
  init: () => [...featureKeys.all, "init"] as const,
  initForm: () => [...featureKeys.all, "initForm"] as const,
  list: () => [...featureKeys.all, "lista"] as const,
  get: (id: string | number) => [...featureKeys.all, "get", id] as const,
  detail: (id: string | number) => [...featureKeys.all, "detalle", id] as const,
};
```

## Form Pattern (Standard)

**`{feature}.schema.ts`** — Zod validation and inferred types:
```ts
const featureBaseFields = {
  nombre: z.string().min(1, "Requerido"),
  estadoCodigo: z.string().min(1, "Requerido"),
};

export const featureCreateSchema = z.object({ ...featureBaseFields });
export const featureEditSchema = z.object({ ...featureBaseFields });

export type FeatureCreateFormValues = z.infer<typeof featureCreateSchema>;
export type FeatureEditFormValues = z.infer<typeof featureEditSchema>;
```

**`{feature}.form-types.ts`** — re-exports the inferred types and defines `featureCreateDefaultValues` / `featureEditDefaultValues` (see `_base`).

## List Hook Pattern

`queryKey` is required; `useListPage` appends page, limit, search and filters to it.

```ts
const { elements, isLoading, pagination, handleSearch, handleFilterApply } =
  useListPage<Feature, FeatureListaFiltros>({
    queryKey: featureKeys.list(),
    fetchData: async (page, limit, search, filtros) => {
      const filtro = mapFeatureListaToFiltro(page, limit, search, filtros);
      const response = await featureService.find(filtro);
      return { elements: response.elements ?? [], total: response.totalCount ?? 0 };
    },
  });
```

## Filter Config Pattern

`FilterFieldConfig` comes from `@/shared/types/filter.types`; `options` are `{ label, value }`. Filters receive data, never fetch:

```ts
// GOOD — receives init data and maps ICombo items to options
export function useFeatureFiltrosConfig(init?: FeatureInit): FilterFieldConfig[] {
  return useMemo(() => [
    {
      id: "estado",
      label: "Estado",
      type: "select",
      options: init?.estados?.list.map((i) => ({ label: i.nombre ?? "", value: i.codigo ?? "" })) ?? [],
    },
  ], [init]);
}
// BAD — calling useQuery (or any fetch) inside the config hook
```

## Enums Usage

**CRITICAL: When creating a new enum, ALWAYS export it from `src/domain/enums/index.ts`.**

```ts
// src/domain/enums/feature-estado.ts
export const FeatureEstado = {
  PENDIENTE: "EST001",
  ACTIVO: "EST002",
} as const;

export type FeatureEstadoType = (typeof FeatureEstado)[keyof typeof FeatureEstado];
```

Use enums as map keys, not hardcoded strings:

```ts
import { FeatureEstado } from "@/domain/enums";

// GOOD — follows the enum if the code changes
const estadoVisual: Record<string, string> = {
  [FeatureEstado.PENDIENTE]: "pending",
};

// BAD — fragile string literals
const estadoVisual: Record<string, string> = {
  EST001: "pending",
};
```

**Visual Mapper Pattern:**

Every feature with enum values shown in list tables MUST have a visual mapper in `mappers/`:

```ts
// mappers/{feature}-tipo-visual.ts
import type { StatusVariant } from "@/shared/components/wrapper/status-badge";
import { FeatureEstado } from "@/domain/enums";

export const featureEstadoVisual: Record<string, StatusVariant> = {
  [FeatureEstado.PENDIENTE]: "pending",
  [FeatureEstado.ACTIVO]: "active",
};
```

Then use it in columns with `StatusBadge` (`@/shared/components/wrapper/status-badge`):

```tsx
cell: ({ row }) => (
  <StatusBadge
    variant={featureEstadoVisual[row.original.estadoCodigo] ?? "default"}
    estado={row.original.estado || "—"}
  />
)
```

## Checklist Before Done

- [ ] Checked the project layout against "Template conventions may change"
- [ ] Domain model in `src/domain/models/` (not inside feature)
- [ ] Enums in `src/domain/enums/` **AND exported from `index.ts`**
- [ ] Visual mapper (`*-tipo-visual.ts`) for enums that appear in tables
- [ ] Service extends `HttpBase` (4 generics max, defaults only where they fit)
- [ ] Filter: domain filter in `domain/models/`, UI filter in `mappers/`, mapper function between them
- [ ] Filter field IDs in mapper match the backend filter field names
- [ ] Query keys centralized, no string literals
- [ ] Mappers separate API<->domain from form<->request
- [ ] Zod schema validates form, types inferred with `z.infer`
- [ ] `form-types.ts` re-exports types + defines defaultValues
- [ ] `FormFooter` used for modal form buttons
- [ ] `useListPage` used for list screens, with a `queryKey`
- [ ] `ICombo` used for select/combo data
- [ ] `import type` only for type annotations

## References

Paths in the target project (the `src/features/_base/README.md` file is gitignored and may be absent; do not rely on it):

- `src/features/_base/api/feature.service.ts` — service skeleton
- `src/features/_base/api/feature.query-keys.ts` — query keys
- `src/features/_base/forms/feature.schema.ts`, `feature.form-types.ts`, `feature-form.constants.ts`, `FeatureForm.tsx` — form pattern with `FormFooter`
- `src/features/_base/mappers/feature.mapper.ts` — filter and form mappers
- `src/core/lib/http-base.ts` — base service class (4 generics)
- `src/core/lib/http-base-with-mapper.ts` — base service with API->domain mappers (3 generics)
- `src/shared/hooks/useListPage.ts` — list hook
- `src/shared/components/form/form-footer.tsx` — form button bar
- `src/shared/components/wrapper/status-badge.tsx` — `StatusBadge`, `StatusVariant`
- `src/shared/types/filter.types.ts` — `FilterFieldConfig`
- `src/domain/models/base/combo.ts` — `ICombo`
- `src/domain/models/base/base-filtro.ts` — `BaseFiltro`
- `src/domain/enums/index.ts` — enums barrel
