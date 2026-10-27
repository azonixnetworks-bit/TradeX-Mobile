# TradeX S3 Support Runtime Asset Manifest

Only assets used by the Flutter implementation were copied from the supplied
bundle. The eight design references remain external design input and are not
registered in `pubspec.yaml`.

## Reused existing asset

| Asset | Use |
|---|---|
| `assets/affiliate/illustrations/dashboard_network_globe.png` | Cropped, low-opacity ornamental background across support screens |

The supplied `01_gold_network_globe.png` was not copied because the repository
already contains the approved TradeX network globe.

## Support images

| Asset | Source dimensions | Use |
|---|---:|---|
| `assets/support/images/gold_orbit_lines.png` | 533×391 RGBA | Sparse top background accent |
| `assets/support/images/gold_wave_overlay.png` | 552×416 RGBA | Available for support card ornament; not used as a screen background |
| `assets/support/images/support_headset_3d.png` | 420×350 RGBA | Live Chat Waiting illustration |
| `assets/support/images/ticket_success_3d.png` | 433×359 RGBA | Ticket Feedback illustration |

The cTrader-style badge, generic people and attachment-placeholder PNGs were
intentionally excluded to avoid presenting placeholder identities/brands/files
as real customer data.

## Support SVG icons

Registered under `assets/support/icons/`:

- `arrow_left.svg`
- `attachment.svg`
- `book_open.svg`
- `calendar.svg`
- `camera.svg`
- `chart_bars.svg`
- `check_circle.svg`
- `chevron_right.svg`
- `clock.svg`
- `credit_card.svg`
- `faq.svg`
- `feedback.svg`
- `file_plus.svg`
- `file_text.svg`
- `headset.svg`
- `help_circle.svg`
- `hourglass.svg`
- `image.svg`
- `live_chat.svg`
- `message_circle.svg`
- `paperclip.svg`
- `search.svg`
- `send.svg`
- `star.svg`
- `support_document.svg`
- `user.svg`
- `x_circle.svg`

Icons are rendered through the existing `flutter_svg` dependency. No package
was added. Unused bundle icons were not copied into runtime assets.
