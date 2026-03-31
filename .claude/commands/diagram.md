---
description: Generate architecture diagrams, flowcharts, ERDs, or wireframes
argument-hint: <what to diagram — e.g. 'provider chain', 'DB schema', 'transaction flow'>
---

# Visualization Mode

## Tool Selection
| Diagram Type | Tool |
|-------------|------|
| Architecture / wireframes | `excalidraw` |
| Sequence / flow / state | `mcp-mermaid` or `claude-mermaid` |
| UML class / package | `draw-uml` |
| ERD (DB schema) | `mcp-mermaid` (erDiagram) |
| Data charts | `antv-chart` or `quickchart` |

## Workflow
1. Read the relevant source code first
2. Choose the right tool
3. Generate with accurate relationships
4. Export (PNG/SVG for docs, interactive for exploration)

## Request: $ARGUMENTS
