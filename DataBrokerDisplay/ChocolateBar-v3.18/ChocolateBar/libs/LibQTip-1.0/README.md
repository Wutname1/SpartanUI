# LibQTip-1.0
LibQTip is designed replace GameTooltip - but with added functionality, such as multiple columns - from a minimalist design perspective.

## Features
- Ability to display and handle multiple tooltips at the same time,
- Unlimited number of columns and lines,
- Column default and per cell justification,
- Tooltip default and per cell font setting,
- Colspans,
- Possibility to add custom cells,
- Optional scrollbar,
- Optional scripts for lines, columns, or cells,
- Optional automatic hiding,
- Frames and tables recycling to reduce resource footprint.

## Caveats
Look [here](https://www.wowace.com/projects/libqtip-1-0/pages/getting-started) for information on embedding the latest beta/release.

**In order to achieve effective frame recycling, tooltips must be released.**

Holding a tooltip leads to the creation of a full set of frames for every AddOn which does not follow this practice. Moreover, releasing a tooltip has a very little overhead compared to its benefits.

## Known issues
Alignment may be altered when using :SetScale after filling the tooltip.

## Documentation
- [Getting Started Guide](https://www.wowace.com/projects/libqtip-1-0/pages/getting-started)
- [How to Add Custom Cells](https://www.wowace.com/projects/libqtip-1-0/pages/how-to-add-custom-cells)
- [API Reference](https://www.wowace.com/projects/libqtip-1-0/pages/api-reference)
- [Standard CellProvider API](https://www.wowace.com/projects/libqtip-1-0/pages/standard-cell-provider-api)
