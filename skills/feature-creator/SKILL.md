---
name: feature-creator
description: "Trigger: crear feature, nueva feature, feature structure, feature scaffold, estructura de feature. Guide for creating features in senasa-casilla-frontend following project conventions."
license: Apache-2.0
metadata:
  author: "carlo"
  version: "1.2"
---

## Activation Contract

Create or scaffold a new feature when:
- User asks to create a new feature, module, or screen
- User mentions feature structure, folders, or conventions
- Extending an existing feature with new screens or endpoints

Do NOT use for:
- One-off components outside feature scope
- Shared utilities (those go in `src/shared/`)
- Domain models (those go in `src/domain/`)

## Hard Rules

1. **Domain models live in `src/domain/models/`**, never inside features. Features import from `@/domain/models/`. This includes interfaces used by services (like InitFormModel types).
2. **Enums live in `src/domain/enums/`**, never inside features. Import from `@/domain/enums`. **ALWAYS export the new enum from `src/domain/enums/index.ts`** — the barrel file.
3. **Services extend `HttpBase`** with exactly 4 generics: `<DataModel, FilterModel, SelectModel, InitFormModel>`. ViewModel is omitted when view returns the same shape as DataModel.
4. **Mappers convert between API response types and domain types**, or form values to request types. Never mix concerns.
5. **Query keys are centralized** in `api/{feature}.query-keys.ts`. Never use string literals like `['features', 'lista']`.
6. **Forms use Zod schemas** for validation. Types are inferred from schemas with `z.infer`. No duplicate validation rules.
7. **`FormFooter`** from `@/shared/components/form/form-footer.tsx` for all modal form buttons.
8. **`useListPage`** from `@/shared/hooks/useListPage` for all list screens. Never `useForm` for pagination.
9. **`import type`** is ONLY for type annotations. If you need the value at runtime (`new`, function call), use regular `import`.
10. **`ICombo`** from `@/domain/models/base/combo` for all combobox/select data. Never create custom combo types.

## Feature Structure

```
src/features/{feature-name}/
├── api/
│   ├── {feature}.service.ts          # HTTP calls, extends HttpBase
│   ├── {feature}.query-keys.ts       # React Query keys
│   └── mappers/                      # API↔Domain mappers (complex features)
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
│   ├── {feature}-filtros.mapper.ts   # UI filter ↔ Domain filter
│   ├── {feature}-tipo-visual.ts      # Enum → StatusBadge variant (colores)
│   └── {feature}.mapper.ts           # Form↔Request conversions
├── modals/
│   ├── {Feature}CreateModal.tsx
│   ├── {Feature}EditModal.tsx
│   └── {Feature}DetailModal.tsx
└── pages/
    └── {feature}-lista-page.tsx      # Route composition (minimal logic)
```

## Domain Models Location

**`domain/models/base/`** — generic, reusable across projects:
- `combo.ts`, `pagination.ts`, `response.ts`, `base-filtro.ts`
- Feature-specific base models: `empresa.ts`, `tupa.ts`

**`domain/models/` (root)** — business-specific to this project:
- `documento-administrado.ts`, `admision.ts`, `usuario.ts`

## HttpBase Generics

HttpBase has exactly **4 generics**:

```ts
export class HttpBase<
  DataModel,      // Main entity (list, save, update)
  FilterModel,    // Filter for search/find (default: Partial<DataModel>)
  SelectModel,    // Selection data (default: Partial<DataModel>)
  InitFormModel   // Init form response (default: SelectModel)
>
```

**`get` vs `getById`:**
- **`get(id)`** → returns `DataModel`. Used for EDITING — brings object to fill edit form, may include ICombos.
- **`getById(id)`** → returns `DataModel`. Used for VIEWING — read-only display.
- **`init()`** → returns `SelectModel`. Used for filter dropdown data.

If view returns a different shape, override `getById` with a custom method returning the view type.

## Service Pattern

```ts
// src/features/{feature}/api/{feature}.service.ts
import { HttpBase } from "@/core/lib/http-base";
import type { Feature, FeatureFiltro, FeatureInit } from "@/domain/models/feature";

class FeatureService extends HttpBase<Feature, FeatureFiltro, Feature, FeatureInit> {
  constructor() {
    super("/feature");  // backend base path
  }

  // Add custom methods here when HttpBase doesn't cover the endpoint
}

export const featureService = new FeatureService();
```

**When to add custom methods:**
- Endpoint doesn't match CRUD patterns (e.g., `/findMisTramites`, `/initAdministrado`)
- Response needs mapping before returning to hooks
- File uploads (use `FormData`)

**`find` vs `search`:** Both return paginated results via POST. Use `find` as standard. `search` exists but is rarely used.

## Filter Pattern

Two filter types coexist:

**1. Domain Filter** (`domain/models/`) — class extending `BaseFiltro`, sent to backend:
```ts
// domain/models/base/feature.ts
import { BaseFiltro } from './base-filtro';

export class FeatureFiltro extends BaseFiltro {
  nombre!: string;
  estadoCodigo!: string;
}
```

**2. UI Filter** (`mappers/`) — type representing user selections in filter drawer:
```ts
// mappers/feature-filtros.mapper.ts
export type FeatureListaFiltros = {
  nombre?: string;
  estado?: string;
};
```

**3. Mapper Function** — converts UI filter to domain filter:
```ts
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

**Usage in hook:**
```ts
useListPage<Feature, FeatureListaFiltros>({
  fetchData: async (page, limit, search, filtros) => {
    const filtro = mapFeatureListaToFiltro(page, limit, search, filtros);
    const response = await featureService.find(filtro);
    return { elements: response.elements ?? [], total: response.totalCount ?? 0 };
  },
});
```

## Mapper Locations

**`api/mappers/`** — API response ↔ domain model (for complex features where backend response differs from domain):
```ts
// api/mappers/feature.mapper.ts
export function mapFeatureResponseToDomain(res: FeatureResponse): Feature {
  return { id: res.id, nombre: res.nombre, estadoCodigo: res.estado?.codigo ?? "" };
}
```

**`mappers/` (root)** — filters, colors, UI transformations, form↔request:
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
  detail: (id: string | number) => [...featureKeys.all, "detail", id] as const,
};
```

## Form Pattern (Standard)

**`schema.ts`** — Zod validation:
```ts
const featureBaseFields = {
  nombre: z.string().min(1, "Requerido"),
  estadoCodigo: z.string().min(1, "Requerido"),
};

export const featureCreateSchema = z.object({ ...featureBaseFields });
export const featureEditSchema = z.object({ ...featureBaseFields });
```

**`form-types.ts`** — re-exports types + default values:
```ts
export type { FeatureCreateFormValues, FeatureEditFormValues } from "./feature.schema";
import type { FeatureCreateFormValues, FeatureEditFormValues } from "./feature.schema";

export const featureCreateDefaultValues: FeatureCreateFormValues = {
  nombre: "",
  estadoCodigo: "",
};
```

## List Hook Pattern

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

Filters receive data, never fetch:

```ts
// GOOD — receives init data
export function useFiltrosConfig(init?: FeatureInit): FilterFieldConfig[] {
  return useMemo(() => [
    { id: "estado", label: "Estado", type: "select", options: init?.estados ?? [] },
  ], [init]);
}

// BAD — fetches inside config
export function useFiltrosConfig(): FilterFieldConfig[] {
  const { data } = useQuery(...);  // ← wrong
}
```

## Enums Usage

**CRITICAL: When creating a new enum, ALWAYS export it from `src/domain/enums/index.ts`.**

Use enums as map keys, not hardcoded strings:

```ts
import { DocumentoEstado } from "@/domain/enums";

// GOOD — auto-updates if enum value changes
const estadoVisual: Record<string, string> = {
  [DocumentoEstado.PENDIENTO]: "pending",
};

// BAD — fragile string literals
const estadoVisual: Record<string, string> = {
  "PENDIENTE": "pending",
};
```

**Visual Mapper Pattern:**

Every feature with enum values that appear in list tables MUST have a visual mapper file in `mappers/`:

```ts
// mappers/{feature}-tipo-visual.ts
import type { StatusVariant } from "@/shared/components/wrapper/status-badge";
import { TipoAuditoria } from "@/domain/enums";

export const auditoriaTipoVisual: Record<string, StatusVariant> = {
  [TipoAuditoria.ACCESO]: "active",
  [TipoAuditoria.DESCARGA]: "in-process",
  [TipoAuditoria.CAMBIO_ESTADO]: "pending",
};
```

Then use it in columns with `StatusBadge`:

```tsx
cell: ({ row }) => (
  <StatusBadge
    variant={auditoriaTipoVisual[row.original.tipoCodigo] ?? "default"}
    estado={row.original.tipo || "—"}
  />
)
```

## Checklist Before Done

- [ ] Domain model in `src/domain/models/` (not inside feature)
- [ ] Enums in `src/domain/enums/` **AND exported from `index.ts`**
- [ ] Visual mapper (`*-tipo-visual.ts`) for enums that appear in tables
- [ ] Service extends `HttpBase` with exactly 4 generics
- [ ] Filter: domain filter in `domain/models/`, UI filter in `mappers/`, mapper function between them
- [ ] Filter field IDs in mapper match the backend filter field names
- [ ] Query keys centralized, no string literals
- [ ] Mappers separate API↔Domain from Form↔Request
- [ ] Zod schema validates form, types inferred with `z.infer`
- [ ] `form-types.ts` re-exports types + defines defaultValues
- [ ] `FormFooter` used for modal form buttons
- [ ] `useListPage` used for list screens
- [ ] `ICombo` used for select/combo data
- [ ] `import type` only for type annotations

## References

- `src/features/_base/README.md` — full template with examples
- `src/core/lib/http-base.ts` — base service class (5 generics)
- `src/shared/hooks/useListPage.ts` — list hook
- `src/shared/components/form/form-footer.tsx` — form button bar
- `src/domain/models/base/combo.ts` — ICombo type
- `src/domain/models/base/base-filtro.ts` — BaseFiltro class
