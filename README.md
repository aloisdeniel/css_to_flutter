# CSS to Flutter

A web tool that converts CSS snippets to Flutter/Dart code. Write CSS on the left, get the equivalent Flutter properties on the right — grouped by TextStyle, Layout, Container, and BoxDecoration.

> Disclaimer: This is pure vibe-coded slop, use it at your own risk. It’s meant for quick prototyping and learning, not production use 

## Supported CSS Properties

### Colors
| CSS Property | Flutter Equivalent |
|---|---|
| `color` | `color: Colors.red` / `Color(0xFF...)` |
| `background-color` | `color: Colors.red` / `Color(0xFF...)` |
| `border-color` | `color: Colors.red` / `Color(0xFF...)` |
| `outline-color` | `color: Colors.red` / `Color(0xFF...)` |

Supported color formats: hex (`#RGB`, `#RRGGBB`, `#RRGGBBAA`), named colors (`red`, `blue`, ...), `rgb()`, `rgba()`.

### Gradients
| CSS Property | Flutter Equivalent |
|---|---|
| `background: linear-gradient(...)` | `LinearGradient(...)` |
| `background: radial-gradient(...)` | `RadialGradient(...)` |
| `background: conic-gradient(...)` | `SweepGradient(...)` |
| `background-image` | Same as above |

Also supports `repeating-linear-gradient` and `repeating-radial-gradient` with `tileMode: TileMode.repeated`. Direction via `to <side>` keywords or angle units (`deg`, `turn`, `rad`, `grad`).

### Typography
| CSS Property | Flutter Equivalent |
|---|---|
| `font-size` | `fontSize` |
| `font-weight` | `fontWeight: FontWeight.bold` / `.w100`–`.w900` |
| `font-style` | `fontStyle: FontStyle.italic` |
| `font-family` | `fontFamily: '...'` |
| `text-align` | `textAlign: TextAlign.center` |
| `text-decoration` | `decoration: TextDecoration.underline` |
| `text-transform` | Comment (handle with `.toUpperCase()`) |
| `letter-spacing` | `letterSpacing` |
| `word-spacing` | `wordSpacing` |
| `line-height` | `height` (unitless, `%`, `em`, `rem`, `px`, `normal`) |
| `text-overflow` | `overflow: TextOverflow.ellipsis` |

### Sizing
| CSS Property | Flutter Equivalent |
|---|---|
| `width` | `width` |
| `height` | `height` |
| `min-width` | `constraints: BoxConstraints(minWidth: ...)` |
| `min-height` | `constraints: BoxConstraints(minHeight: ...)` |
| `max-width` | `constraints: BoxConstraints(maxWidth: ...)` |
| `max-height` | `constraints: BoxConstraints(maxHeight: ...)` |

### Spacing
| CSS Property | Flutter Equivalent |
|---|---|
| `margin` | `margin: EdgeInsets.all(...)` / `.symmetric(...)` / `.only(...)` |
| `margin-top` / `right` / `bottom` / `left` | `margin: EdgeInsets.only(...)` |
| `padding` | `padding: EdgeInsets.all(...)` / `.symmetric(...)` / `.only(...)` |
| `padding-top` / `right` / `bottom` / `left` | `padding: EdgeInsets.only(...)` |

Shorthand syntax (1–4 values) is supported.

### Border
| CSS Property | Flutter Equivalent |
|---|---|
| `border` | `Border.all(...)` |
| `border-radius` | `borderRadius: BorderRadius.circular(...)` |
| `border-top-left-radius` | `borderRadius: BorderRadius.only(topLeft: ...)` |
| `border-top-right-radius` | `borderRadius: BorderRadius.only(topRight: ...)` |
| `border-bottom-left-radius` | `borderRadius: BorderRadius.only(bottomLeft: ...)` |
| `border-bottom-right-radius` | `borderRadius: BorderRadius.only(bottomRight: ...)` |
| `border-width` | `width: ...` |
| `border-style` | `style: BorderStyle.solid` |
| `border-color` | `color: ...` |

### Layout
| CSS Property | Flutter Equivalent |
|---|---|
| `display` | Comment (use `Row`, `Column`, `Wrap`, etc.) |
| `flex-direction` | Comment (use `Row` or `Column`) |
| `justify-content` | `mainAxisAlignment: MainAxisAlignment.center` |
| `align-items` | `crossAxisAlignment: CrossAxisAlignment.center` |
| `align-self` | Comment (use `Align` widget) |
| `flex-wrap` | Comment (use `Wrap` widget) |
| `flex` | `flex: 1` |
| `flex-grow` | `flex: 1` |
| `flex-shrink` | Comment (use `Flexible` widget) |
| `gap` | Comment (use `SizedBox` between children) |
| `overflow` | `clipBehavior: Clip.hardEdge` |
| `position` | Comment (use `Stack` + `Positioned`) |
| `opacity` | `opacity: 0.5` |

### Positioning
| CSS Property | Flutter Equivalent |
|---|---|
| `top` | `top: ...` (inside `Positioned`) |
| `right` | `right: ...` (inside `Positioned`) |
| `bottom` | `bottom: ...` (inside `Positioned`) |
| `left` | `left: ...` (inside `Positioned`) |
| `inset` | `top/right/bottom/left` (shorthand, 1–4 values) |
| `z-index` | Comment (control with child order in `Stack`) |

### Shadows
| CSS Property | Flutter Equivalent |
|---|---|
| `box-shadow` | `boxShadow: [BoxShadow(offset: ..., blurRadius: ..., spreadRadius: ...)]` |
| `text-shadow` | `Shadow(offset: ..., blurRadius: ...)` |

## Unsupported Properties (need conversion logic)

The following common CSS properties are not yet converted and will appear as "Unsupported" in the output. Contributions welcome!

### Transform & Animation
- `transform` (rotate, scale, translate, skew) — `Transform` widget / `Matrix4`
- `transform-origin` — `alignment` on `Transform`
- `transition` — `AnimatedContainer` / `AnimationController`
- `animation` — `AnimationController` + `Tween`

### Background
- `background-position` — `alignment` in `DecorationImage`
- `background-size` — `fit` in `DecorationImage` (`BoxFit.cover`, etc.)
- `background-repeat` — `repeat` in `DecorationImage` (`ImageRepeat`)
- `background-attachment` — No direct equivalent

### Flexbox & Grid (advanced)
- `order` — Reorder children in `Row`/`Column`
- `flex-basis` — `SizedBox` or `Flexible` with fixed size
- `grid-template-columns` / `grid-template-rows` — `GridView` / `Table`
- `grid-gap` / `column-gap` / `row-gap` — Spacing in `GridView`

### Text (advanced)
- `text-indent` — No direct equivalent (use padding)
- `text-shadow` with color — `Shadow(color: ...)` (color extraction not yet implemented)
- `white-space` — `softWrap` / `maxLines` on `Text`
- `overflow-wrap` / `word-break` — `TextOverflow` or `softWrap`

### Visual Effects
- `filter` (blur, brightness, etc.) — `BackdropFilter` / `ImageFilter`
- `backdrop-filter` — `BackdropFilter`
- `mix-blend-mode` — `BlendMode` on `ColorFiltered`
- `clip-path` — `ClipPath` with custom `CustomClipper`
- `cursor` — `SystemMouseCursors` on `MouseRegion`
- `visibility` — `Visibility` widget

### Border (advanced)
- `border-top` / `border-right` / `border-bottom` / `border-left` — `Border(top: BorderSide(...), ...)`
- `outline` / `outline-offset` — No direct equivalent (use `Container` with extra border)

### Misc
- `box-sizing` — Flutter always uses `border-box`
- `object-fit` — `BoxFit` on `Image`
- `aspect-ratio` — `AspectRatio` widget
- `list-style` — `ListView` with custom builders
- `scroll-behavior` — `ScrollPhysics`
