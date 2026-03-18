---
description: Generate architecture diagrams, flowcharts, ERDs, or wireframes
argument-hint: <what to diagram — e.g. 'provider chain', 'DB schema', 'transaction flow'>
---

# Visualization Mode

Generate a diagram for Masarify's architecture or features.

## Tool Selection
| Diagram Type | Tool | Format |
|-------------|------|--------|
| Architecture / component diagrams | `excalidraw` | Interactive canvas |
| Wireframes / UI mockups | `excalidraw` | Interactive canvas |
| Sequence / flow diagrams | `claude-mermaid` or `mcp-mermaid` | SVG/PNG |
| State machines | `mcp-mermaid` | SVG/PNG |
| UML class / package diagrams | `draw-uml` | SVG/PNG |
| Entity-relationship (DB schema) | `mcp-mermaid` (erDiagram) | SVG/PNG |
| Data charts / analytics | `antv-chart` or `quickchart` | PNG |

## Workflow
1. **Read** the relevant source code to understand the actual structure
2. **Choose** the right tool based on diagram type (see table above)
3. **Generate** the diagram with accurate relationships and labels
4. **Export** to a usable format (PNG/SVG for docs, interactive for exploration)

## Masarify Key Structures to Diagram
- **Provider dependency graph:** 21 Riverpod providers with watch/read chains
- **DB schema ERD:** 12 tables with FK relationships and cascades
- **Feature map:** 19 features under `lib/features/`
- **Navigation flow:** 50+ routes in `app_router.dart`
- **AI pipeline:** Voice (Gemini) → Parse → Review → Save; SMS → OpenRouter → Enrich
- **Clean architecture layers:** Domain → Data → Features → Shared

## Request: $ARGUMENTS
