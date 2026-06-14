# Third-Party Skills Notice

The following skill folders under `.claude/skills/` were copied from
[dpearson2699/swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills)
(commit at time of copy: `main`, June 2026):

`swift-language`, `swift-api-design-guidelines`, `swift-architecture`,
`swift-concurrency`, `swift-testing`, `swift-codable`, `swiftdata`,
`swift-security`, `swiftlint`, `swiftui-patterns`, `swiftui-layout-components`,
`swiftui-navigation`, `swiftui-animation`, `swiftui-performance`,
`swiftui-liquid-glass`, `widgetkit`, `app-intents`, `alarmkit`, `core-motion`,
`push-notifications`, `background-processing`, `permissionkit`, `mapkit`,
`ios-localization`, `ios-accessibility`, `ios-simulator`, `debugging-instruments`.

Only each skill's `SKILL.md` and `references/` directory were copied; the
repository's `evals/` self-test harnesses, `.mcp.json` (a `tessl` MCP server used
by the upstream repo's own tooling), and marketplace/plugin config were **not**
copied — they are unrelated to the skill content itself.

**License**: PolyForm Perimeter 1.0.0 — Required Notice: "Copyright (c) 2025
dpearson2699 (https://github.com/dpearson2699)". Permits use and modification;
restricts redistributing this content as a competing rebranded skills product.
Fine for use as internal reference material in this app's development.

**Security review performed before copying**: scanned all files for shell
exec/network-exfiltration patterns (`curl`, `wget`, `eval`, `subprocess`, etc.).
All matches were benign code examples within documentation (e.g. a curl example
for testing APNs push, PyTorch `model.eval()` calls, `nscurl` ATS diagnostics).
No scripts, hooks, or MCP servers were introduced by this copy.
