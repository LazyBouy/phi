> NOTICE: Text in quotation marks in this file is the reference app's own visible wording. It is reference evidence only and must not be copied into any product.

# R4 — Reference "add node" panel: openers, categories and grouping (facts only)

Observation date: 2026-10-12. Reference app: the locally running reference container (image tag 2.43.0), used only through its web UI and the HTTP responses its pages received. Account: the local member account (not the owner). Browser: headless Chromium, 1440 × 900 viewport, scale 1. Light and dark captures were taken by switching the browser's colour-scheme preference; the app followed it live. All screenshot names below live in `docs/specs/n8n-vibe/_ref/n8n/` and start with `40-node-panel-`; "(L/D)" means both a `-light.png` and a `-dark.png` exist, "(L)" means light only.

Terms used in this report (mine, not the reference's):
- trigger mode: the panel showing the "What triggers this workflow?" root;
- next-step mode: the panel showing the "What happens next?" root;
- category row: a row with a trailing right-arrow that opens another list inside the panel;
- node row: a row that adds a node immediately (no trailing arrow);
- app row: a row for an integration that opens a list of that integration's actions and triggers;
- built-in row: a row whose icon the reference app serves itself, with no verification badge;
- verified community row: a row with a small check-seal badge after the name and an icon loaded from a remote host. The reference lists about a thousand of these in its panel although none is installed (see C6 and F8), so every large count below is split into built-in and community.

---

## A. Openers and modes

A1. An empty new workflow shows one centred placeholder on the canvas: a 100 × 100 px square with a dashed outline and a plus sign, with the label "Add first step…" underneath. — `opener-empty-placeholder` (L)

A2. Clicking that placeholder opens the panel on the right in trigger mode. The header is a title ("What triggers this workflow?") plus a one-line subtitle ("A trigger is a step that starts your workflow"), with no back arrow and no icon. Below it are the search box and 8 rows (listed in B1–B8). — `trigger-root` (L/D)

A3. After "Trigger manually" was picked from that root, the placeholder disappeared and the trigger node showed a short connector stub from its output that ended in a small square "+". — `pick-trigger-manually-result` (L)

A4. Clicking the "+" at the end of a node's output, in a workflow that already contains a trigger, opens next-step mode. The header is a title only ("What happens next?"), with no subtitle and no back arrow, on a light-grey band with a thin rule below it. Then come the search box and 7 rows (B11–B17). — `next-root` (L/D)

A5. In a workflow with no trigger at all (a single Code node), the same output "+" opened trigger mode (as in A2), not next-step mode. — `output-plus-no-trigger` (L/D)

A6. Hovering a connection between two nodes shows a small floating toolbar centred on the line. It holds two 28 px icon buttons: "Add node" (a plus) and "Delete connection" (a bin). — `opener-connection-hover` (L)

A7. Clicking "Add node" on a connection opened next-step mode with the same header and rows as A4. — `open-from-connection` (L/D)

A8. The canvas has a vertical stack of four 36 px icon buttons at its top-right corner: "Open nodes panel" (a plus), "Command bar" (a magnifier), "Add sticky note" and "Open focus panel". The plus opened next-step mode in a workflow with a trigger and trigger mode in a workflow without one. — `open-from-toolbar-plus` (L/D), `opener-empty-placeholder` (L)

A9. While the panel is open, that four-button stack is not on screen; the panel covers the right edge of the canvas. — `open-from-toolbar-plus` (L/D)

A10. Pressing "n" or "N" with the canvas focused opened the panel, using the same mode rule as A8. Focus went to the search box. — `kbd-arrowdown-active` (L)

A11. Pressing Tab on the canvas did not open the panel. Instead a dark hint card appeared next to the toolbar plus, with the bold line "Press N to browse nodes", the text "We changed the shortcut to improve keyboard navigation" and an accent-coloured "Got it" button. The card was gone after a page reload. Shift+A did nothing. — `opener-shortcut-hint` (L/D)

A12. The last row of the next-step root, "Add another trigger", opens the trigger-mode list inside the panel. This copy has a back arrow before the title, keeps the subtitle, uses an 88 px header with no grey band, and shows the same 8 rows as A2. — `next-add-another-trigger` (L/D)

A13. In a workflow that already had a trigger, no separate "add trigger" control was seen on the canvas. Triggers were reachable through the A12 row and through search, because next-step search results include triggers (E6).

A14. An "AI Agent" node on the canvas has three labelled connector stubs under it: "Chat Model" (with a red asterisk), "Memory" and "Tool". Each ends in a small "+". — `opener-subnode-connectors` (L)

A15. Each connector "+" opens a filtered panel. Its header is the category's icon followed by a title ("Language Models", "Memory" or "Tools"), on the grey band, with no back arrow and no subtitle. — `opener-subnode-chat-model` (L/D), `opener-subnode-memory` (L/D), `opener-subnode-tool` (L/D)

A16. The toolbar magnifier opens a centred command palette with the placeholder "Type a command or search...". Typing "sheet" listed "Add Google Sheets" and "Add Google Sheets Tool" under a "Nodes" label. This is a second way to add nodes that does not use the panel. — `opener-command-bar` (L)

A17. The "+" at the top of the far-left sidebar ("Add new item") opens a menu with "New workflow", "New agent", "New credential", "New data table" and a locked "New project". It does not open the node panel. — `opener-sidebar-add-menu` (L)

A18. The panel always reopened at its root. After the panel was closed while showing the Flow list and then reopened, it showed the root, not Flow.

A19. Clicking the canvas outside the open panel closed the panel. Escape also closed it (see G9).

## B. Root rows

Trigger-mode root (a single flat list, with no section labels or dividers):

B1. Row 1, "Trigger manually". Icon: a mouse pointer with click arcs around its tip. Description: "Runs the flow on clicking a button in n8n. Good for getting started quickly". No trailing arrow, so it adds the node directly. — `trigger-root` (L/D)

B2. Row 2, "On app event". Icon: a satellite dish. Description: "Runs the flow when something happens in an app like Telegram, Notion or Airtable". Trailing right-arrow; it opens a list. — `trigger-root`

B3. Row 3, "On a schedule". Icon: a clock face. Description: "Runs the flow every day, hour, or custom interval". No arrow. — `trigger-root`

B4. Row 4, "On webhook call". Icon: the three-linked-circles webhook symbol. Description: "Runs the flow on receiving an HTTP request". No arrow. — `trigger-root`

B5. Row 5, "On form submission". Icon: a clipboard with lines. Description: "Generate webforms in n8n and pass their responses to the workflow". No arrow. — `trigger-root`

B6. Row 6, "When executed by another workflow". Icon: an arrow entering a bracket. Description: "Runs the flow when called by the Execute Workflow node from a different workflow". No arrow. — `trigger-root`

B7. Row 7, "On chat message". Icon: a speech bubble. Description: "Runs the flow when a user sends a chat message. For use with AI nodes". No arrow. — `trigger-root`

B8. Row 8, "Other ways...". Icon: an open folder. Description: "Runs the flow on workflow errors, file changes, etc.". Trailing arrow. — `trigger-root`

B9. All root icons are thin grey line icons. The two category rows (B2, B8) use a 26 px icon box; the node rows show the node's own icon at 20 or 24 px. The trailing arrows are light grey. — `trigger-root`

B10. The trigger root had the same rows whichever way it was reached: from the empty placeholder, from the toolbar plus or an output "+" in a workflow without a trigger, or from "Add another trigger". Only the header differed: a back arrow appears in the last case. — `trigger-root`, `output-plus-no-trigger`, `next-add-another-trigger`

Next-step root:

B11. Row 1, "AI". Icon: a robot head. Description: "Build autonomous agents, summarize or search documents, etc.". Trailing arrow. — `next-root` (L/D)

B12. Row 2, "Action in an app". Icon: a globe. Description: "Do something in an app or service like Google Sheets, Telegram or Notion". Arrow. — `next-root`

B13. Row 3, "Data transformation". Icon: a pencil. Description: "Manipulate, filter or convert data". Arrow. — `next-root`

B14. Row 4, "Flow". Icon: a branching line (one stem forking into two). Description: "Branch, merge or loop the flow, etc.". Arrow. — `next-root`

B15. Row 5, "Core". Icon: a toolbox. Description: "Run code, make HTTP requests, set webhooks, etc.". Arrow. — `next-root`

B16. Row 6, "Human review". Icon: a scalloped badge with a check mark. Description: "Request approval via services like Slack and Telegram before making tool calls". Arrow. — `next-root`

B17. A thin horizontal rule, inset 16 px on both sides, comes next. Row 7 below it is "Add another trigger". Icon: a filled lightning bolt. Description: "Triggers start your workflow. Workflows can have multiple triggers.". Arrow. The root has no section labels. — `next-root`

B18. All 7 next-step root rows are category rows, and all use 26 px grey line icons. None of them adds a node directly. — `next-root`

B19. The next-step root, and with it the "Add another trigger" row, appeared only in workflows that already contained a trigger. In a workflow without one, every opener tried gave trigger mode (A5, A8), so I could not see the next-step root without a trigger. — `output-plus-no-trigger`

B20. The "Tool" connector panel (A15) has its own root. It starts with an expanded section "Recommended Tools" holding 4 node rows: "AI Agent Tool", "Call n8n Workflow Tool", "Code Tool" and "HTTP Request Tool". A rule follows, then 4 category rows: "Action in an app", "MCP servers" (with a green "New" pill), "Vector Stores" and "Human review". — `opener-subnode-tool` (L/D)

B21. When a view opens, one row is already highlighted by a 2 px accent-orange bar at its left edge. On both roots it is the first row. In "Data transformation", "Core" and the app views it was the first item, below the first section header. In "Vector Stores" and the Tool connector root, the first section header itself ("For Beginners", "Recommended Tools") was highlighted. — `trigger-root`, `next-root`, `next-core`, `next-ai-other-vector-stores` (L), `opener-subnode-tool`

## C. Contents of each root row's sub-view

General patterns:

C1. A category sub-view header has a back arrow, the category's own icon (20 px) and the title, on the grey band with a rule below. Views that carry a subtitle ("AI Nodes", "Other AI Nodes" and the trigger list opened from "Add another trigger") instead show a back arrow, a title and an indented subtitle, with no icon and no grey band. — `next-data-transformation` (L/D), `next-ai` (L/D)

C2. A section header is a bold label across the full width, with a chevron at the right (pointing down when the section is expanded and up when it is collapsed) and a thin rule below. Clicking the header toggles the section. In the built-in category lists every section starts expanded, and a collapsed section was expanded again after leaving the view and coming back. — `next-data-transformation`, `next-data-transformation-section-collapsed` (L)

C3. A list row has the icon on the left, then the name, then an optional description of one or more lines. Badges sit straight after the name: an orange bolt for triggers, a dark check-seal for verified community items, and small tags such as "Recommended", "Preview", "New", "Beta" and "Deprecated". A row that opens another list ends in a light-grey right-arrow. Long descriptions wrap in full; the tallest wrapped row seen was 223 px. — `next-core` (L/D), `trigger-app-event` (L/D)

C4. Short lists hide the search box. It was missing in "Other ways..." (5 items), "Memory" (6), "Document Loaders" (1), "Output Parsers" (3), "Retrievers" (4) and "Text Splitters" (3). It was present in "Flow" (9 items) and in every larger list. Roots and app action lists always had it. — `trigger-other-ways` (L/D), `next-ai-other-memory` (L), `next-ai-other-document-loaders` (L)

Trigger-mode sub-views:

C5. "On app event" is one flat list of 1,279 rows with no sections, sorted alphabetically without regard to case, digits first. The header is a back arrow, the dish icon and "On app event"; the search placeholder is "Search nodes...". The first 15 rows are "1MSG for WhatsApp Business API", "1Shot API", "2Captcha", "2Chat Trigger", "42min", "A.I. Slides by Brightdeck", "Abyssale", "Acquibee", "Acrewity", "Actaport", "Action Network", "ActiveCampaign", "ActivitySmith", "Acuity Scheduling" and "Adalo". — `trigger-app-event` (L/D)

C6. Of those 1,279 rows:
- 282 are built-in, with no description and no badge. 255 of them are app rows with an arrow. The other 27 add a node directly; most are named "… Trigger" and carry the bolt (for example "AMQP Trigger", "Bitbucket Trigger", "Kafka Trigger", "Typeform Trigger"), and a few have no bolt ("DHL", "LingvaNex", "Mailcheck", "MSG91", "OpenThesaurus").
- 997 are verified community rows. All have the check-seal and an arrow, and all but one have a description.
- 88 rows carry the trigger bolt.
- One built-in row, "Microsoft Agent 365 Trigger", carries a grey "Beta" tag.
- The list also contains "Manual Trigger", "Schedule Trigger", "Webhook", "Email Trigger (IMAP)" and "RSS Feed Trigger".

— `trigger-app-event`

C7. An app opened in trigger mode ("Google Sheets") has a header with a back arrow, the app logo and the app name, and the search placeholder "Search Google Sheets Actions...". The section "Triggers (3)", with an orange bolt after its label, comes first and is expanded. It lists "On row added", "On row updated" and "On row added or updated", each 36 px tall with the app logo and a bolt. Below it, "Actions (10)" is collapsed. — `trigger-app-google-sheets` (L/D)

C8. Expanding "Actions (10)" in trigger mode shows a bordered note first: "Actions need to be triggered by another node, e.g. at regular intervals with the Schedule node. Learn more". The actions follow, grouped under small all-caps labels: "DOCUMENT ACTIONS" (2: "Create spreadsheet", "Delete spreadsheet") and "SHEET WITHIN DOCUMENT ACTIONS" (8: "Append or update row in sheet", "Append row in sheet", "Clear sheet", "Create sheet", "Delete sheet", "Delete rows or columns from sheet", "Get row(s) in sheet", "Update row in sheet"). — `trigger-app-google-sheets-actions-expanded` (L/D)

C9. An app with no triggers ("Bitly") in trigger mode:
- "Triggers (2)" holds the note "No Bitly Triggers available. Users often combine the following Triggers with Bitly Actions.", followed by two generic rows, "On a Schedule" and "On a Webhook call".
- "Actions (3)" is expanded. Its header has a small "?" icon whose tooltip reads "Actions perform a step once your workflow has already started. Learn more". It contains the activation note from C8 and 3 actions.
- The view ends with a plain line, "Didn't find the right event? Make a custom Bitly API call", with an accent-coloured link.

— `trigger-app-no-triggers` (L/D), `trigger-app-actions-info-tooltip` (L)

C10. "Other ways..." has 5 rows in alphabetical order, with no search box and no sections: "Email Trigger (IMAP)", "Error Trigger", "MCP Server Trigger", "n8n" (an app row with an arrow and the description "Handle events and perform actions on your n8n instance") and "SSE Trigger". Every row except "n8n" carries the bolt. — `trigger-other-ways` (L/D)

Next-step sub-views:

C11. "AI" has the header "AI Nodes" with the subtitle "Select an AI Node to add to your workflow". Its 18 rows are in a curated order, with no section labels:
- "AI Templates" ("Recommended" tag, arrow), followed by a rule;
- "Message an Agent" (purple "Preview" pill, arrow);
- "AI Agent" (node row);
- 8 provider app rows in alphabetical order, each with an arrow: "Anthropic", "Google Gemini", "Guardrails", "MiniMax", "Moonshot Kimi", "Ollama", "OpenAI", "Qwen Cloud";
- 6 node rows in alphabetical order: "Basic LLM Chain", "Information Extractor", "Question and Answer Chain", "Sentiment Analysis", "Summarization Chain", "Text Classifier";
- a rule, then "Other AI Nodes" (arrow; "Embeddings, Vector Stores, LLMs and other AI nodes").

— `next-ai` (L/D), `next-ai-bottom` (L/D)

C12. A provider's sub-view ("OpenAI") holds "Actions (16)" grouped under all-caps labels: "TEXT ACTIONS" (2), "IMAGE ACTIONS" (3), "AUDIO ACTIONS" (3), "FILE ACTIONS" (3), "CONVERSATION ACTIONS" (4) and "VIDEO ACTIONS" (1). — `next-ai-openai-actions` (L)

C13. "Other AI Nodes" has a back arrow, its title and the same subtitle, then 10 category rows, each with a description and an arrow. In order (not alphabetical), with item counts: "Document Loaders" (1), "Language Models" (33), "Memory" (6), "Output Parsers" (3), "Retrievers" (4), "Text Splitters" (3), "Tools" (1,085), "Embeddings" (13), "Vector Stores" (13), "Miscellaneous" (10). — `next-ai-other` (L/D)

C14. Notes on each AI sub-category:
- "Language Models": a notice with an amber left bar first ("Chat models are designed for interactive conversations and follow instructions well, while text completion models focus on generating continuations of a given text input"), then 33 rows in alphabetical order: 25 built-in node rows and 8 verified community rows. The first rows are "Anthropic Chat Model", "AWS Bedrock Chat Model", "Azure AI Foundry Chat Model", "Cohere Chat Model", "Cohere Model", "Databricks Chat Model" and "DeepSeek Chat Model".
- "Memory": a notice ("Memory allows an AI model to remember and reference past interactions with it") and 6 rows.
- "Vector Stores": a notice, then two sections, "For Beginners" (1: "Simple Vector Store") and "Other Vector Stores" (12, alphabetical).
- "Output Parsers": "Auto-fixing Output Parser" carries a grey "Deprecated" tag.
- "Tools": one flat alphabetical list of 1,085 rows (298 built-in, 787 verified community). Nearly all are named "<App> Tool"; the list also holds the vector stores and items such as "Calculator" and "Chat".
- "Miscellaneous": the 8 provider apps from C11, plus "Chat Memory Manager" and one verified community row, "Zenlayer".

— `next-ai-other-language-models` (L/D), `next-ai-other-memory`, `next-ai-other-vector-stores`, `next-ai-other-output-parsers`, `next-ai-other-tools` (L/D), `next-ai-other-miscellaneous`, `next-ai-other-embeddings`, `next-ai-other-retrievers`, `next-ai-other-text-splitters` (all L unless marked)

C15. In the model, memory and similar sub-node lists, each logo sits on a 40 px round light-grey disc. — `next-ai-other-language-models`, `opener-subnode-chat-model`

C16. "Action in an app" is one flat alphabetical list of 1,322 rows with no sections:
- 316 rows are built-in. 256 of them are app rows with an arrow. 60 are node rows: 37 of those have the description "HTTP request" (for example "AlienVault", "Auth0", "Datadog", "Miro", "VirusTotal"), and the rest include "Sticky Note".
- 1,006 rows are verified community rows.

The first 15 rows are the same as in C5, except that "2Chat" replaces "2Chat Trigger". — `next-action-in-an-app` (L/D)

C17. The messaging apps that appear under "Human review" are not in "Action in an app". "Slack", "Gmail", "Telegram", "Discord", "Google Chat", "Microsoft Teams", "Microsoft Outlook" and "WhatsApp Business Cloud" are absent from the full list. Searching "slack" inside "Action in an app" showed Slack only under "Results in other categories". The AI provider apps from C11 are absent from "Action in an app" as well. — `next-action-in-an-app-search-slack` (L)

C18. An app opened in next-step mode ("Google Sheets") shows "Actions (10)" first and expanded, with the same all-caps resource labels as C8 but no activation note. "Triggers (3)" comes last and is collapsed, the reverse of trigger mode. — `next-app-google-sheets` (L/D)

C19. An app with no triggers ("Bitly") in next-step mode shows only "Actions (3)" plus the "custom … API call" line; there is no Triggers section. — `next-app-no-triggers` (L/D)

C20. Further action groupings, read as panel text (no screenshot):
- "Airtable": "Actions (8)" under "BASE ACTIONS" (2) and "RECORD ACTIONS" (6), then a collapsed "Triggers (1)".
- "Data table" (from Core): "Actions (12)" under "ROW ACTIONS" (7) and "TABLE ACTIONS" (5).
- "n8n" (from Core): "Actions (15)" under "AUDIT ACTIONS" (1), "CREDENTIAL ACTIONS" (3), "EXECUTION ACTIONS" (3) and "WORKFLOW ACTIONS" (8), then "Triggers (3)".

C21. A built-in node with a single resource shows its actions without labels. "Code" gives "Actions (2)": "Code in JavaScript" and "Code in Python". "Date & Time" has 7 actions and "Convert to File" has 10. — `next-node-code-actions` (L/D)

C22. "Data transformation" has 5 sections, all expanded, holding 20 rows in total, all built-in and alphabetical within each section: "Popular" (3), "Add or remove items" (4), "Combine items" (3), "Convert data" (8) and "Other" (2). — `next-data-transformation` (L/D)

C23. "Flow" has "Popular" (4) and "Other" (5). — `next-flow` (L/D)

C24. "Core" has "Popular" (4) and "Other" (12). — `next-core` (L/D)

C25. "Human review" has one section, "Send and wait for response", with 11 rows in case-insensitive alphabetical order. 10 are built-in messaging rows showing only a logo and a name, with no description and no arrow. One is a verified community row, "cQnce Approval", with a description and an arrow. — `next-human-review` (L/D)

C26. The sub-views of the Tool connector panel:
- "Action in an app" lists 1,058 rows named "<App> Tool", alphabetically.
- "MCP servers" puts "MCP Client Tool" first, in its own block with a rule below it, then 77 rows named "<Name> MCP" in alphabetical order. All 78 rows are node rows with no arrow.
- "Vector Stores" has the same structure as in C14.
- "Human review" has 10 node rows (no community row).

— `tool-mode-action-in-an-app`, `tool-mode-mcp-servers`, `tool-mode-vector-stores`, `tool-mode-human-review` (all L)

C27. The Chat Model connector panel has a notice followed by 35 rows that are not in alphabetical order. It opens with 5 verified community rows ("Baseten Chat Model", "Eden AI Chat Model", "Merge Gateway Chat Model", "Multiverse CompactifAi", "BoldRouter Chat Model"), then "Qwen Cloud Chat Model", "Anthropic Chat Model", "Azure AI Foundry Chat Model" and so on. The Memory connector panel has a notice, then two sections, "For beginners" (1: "Simple Memory") and "Other memories" (5), and no search box. — `opener-subnode-chat-model` (L/D), `opener-subnode-memory` (L/D)

C28. "Message an Agent" opens a sub-view that shows only its title and the empty state "No agents in this project yet". — `next-ai-message-agent` (L)

## D. Membership facts for mapping

D1. "Data transformation":
- "Popular": "Code", "Date & Time", "Edit Fields (Set)";
- "Add or remove items": "Filter", "Limit", "Remove Duplicates", "Split Out";
- "Combine items": "Aggregate", "Merge", "Summarize";
- "Convert data": "Compression", "Convert to File", "Crypto", "Edit Image", "Extract from File", "HTML", "Markdown", "XML";
- "Other": "Rename Keys", "Sort".

The rows with an arrow (which open an actions list) are "Code", "Date & Time", "Remove Duplicates", "Compression", "Convert to File", "Edit Image", "Extract from File" and "HTML". — `next-data-transformation` (L/D)

D2. "Flow":
- "Popular": "Filter", "If", "Loop Over Items (Split in Batches)", "Merge";
- "Other": "Compare Datasets", "Execute Sub-workflow" (arrow), "Stop and Error", "Switch", "Wait".

— `next-flow` (L/D)

D3. "Core":
- "Popular": "Code" (arrow), "Data table" (arrow), "HTTP Request", "Webhook" (bolt);
- "Other": "E2E Test Polling Trigger" (bolt), "Execute Sub-workflow" (arrow), "Execution Data", "FTP" (arrow), "Guardian" (verified community, arrow), "Guardian Approval Trigger" (verified community, bolt, arrow), "n8n" (arrow), "n8n Form" (arrow), "No Operation, do nothing", "Respond to Webhook", "Track Time Saved", "Wait".

— `next-core` (L/D)

D4. "Human review": "Chat", "cQnce Approval" (verified community), "Discord", "Gmail", "Google Chat", "Microsoft Outlook", "Microsoft Teams", "Send Email", "Slack", "Telegram", "WhatsApp Business Cloud". — `next-human-review` (L/D)

D5. "AI": the top-level rows are listed in C11. Its sub-groups are the 10 categories under "Other AI Nodes" listed in C13. — `next-ai`, `next-ai-other`

D6. Nodes found in more than one category:
- "Code": Data transformation and Core;
- "Filter" and "Merge": Data transformation and Flow;
- "Execute Sub-workflow" and "Wait": Flow and Core;
- "Send Email": Human review and Action in an app;
- the 8 AI provider apps: the AI view and "Miscellaneous";
- all 13 vector stores: "Vector Stores" and "Tools";
- "Webhook": Core and the trigger-mode "On app event" list;
- "n8n": Core and "Other ways...".

— the screenshots listed in D1–D4 and C10, C14

D7. Verified community items are mixed into built-in categories, not kept in a separate area. Examples: "Guardian" and "Guardian Approval Trigger" in Core, "cQnce Approval" in Human review, and 8 community models in Language Models. — `next-core`, `next-human-review`, `next-ai-other-language-models`

D8. The trigger "On app event" list and "Action in an app" overlap but are not the same:
- 88 rows appear only in the trigger list. 20 of them are built-in, for example "Manual Trigger", "Schedule Trigger", "Webhook", "Email Trigger (IMAP)", "RSS Feed Trigger", "Facebook Lead Ads Trigger" and "Typeform Trigger".
- 131 rows appear only in "Action in an app". 54 of them are built-in, for example the 37 "HTTP request" rows from C16, "AMQP Sender", "GraphQL", "Kafka", "MQTT", "MCP Client", "RSS Read", "Send Email" and "Sticky Note".

— `trigger-app-event`, `next-action-in-an-app`

## E. Search

E1. Search at either root returns one flat list with no grouping by category, ordered by relevance (an exact name match came first). When packages from the open community also match, the list ends with a collapsible section "More from the community". The results for "sheet", "http" and "filter" were identical in trigger mode and next-step mode: the same rows in the same order. — `trigger-search-sheet` (L/D), `next-search-sheet` (L/D)

E2. "sheet" returned 22 rows, then the community section:
- "Google Sheets", "Data table" (with the "Recommended" tag), "Microsoft Excel (OneDrive)", "Extract from File", "Convert to File", "Microsoft Excel (SharePoint)", "Schedule Trigger", "Sharetribe Trigger", eight "Status Check … Trigger" rows and "ApiFlash Screenshots";
- under "More from the community": "SuperHippo AI Voice Agents Tool", "ScreenshotRender Tool", "SuperHippo AI Voice Agents", "SEA Post Purchase Survey Trigger" and "rrule.net Schedule Trigger". None of these rows has a verification badge. The two "… Tool" rows show their logo on a round grey disc, and the two "… Trigger" rows carry the bolt.

— `trigger-search-sheet`, `trigger-search-sheet-community` (L/D), `next-search-sheet`

E3. "http" returned 6 rows and no community section: "HTTP Request", "Webhook", "HTML to PDF", "HTML/CSS to Image API", "WhatsAble for WhatsApp" and "ChatArchitect WhatsApp". — `next-search-http` (L/D)

E4. "filter" returned 11 rows, then the community section:
- "Filter", "Edit Fields (Set)", "If", "Switch", "Execution Data", "Fillout Trigger", "finlight Webhook Trigger", "Formidable Forms Trigger", "Venafi TLS Protect Datacenter", "WoopSocial Watch Failed Posts Trigger" and "Status Check Validation Failed Trigger";
- under "More from the community": "IBM Quantum Error (Unofficial) Trigger".

— `next-search-filter` (L/D)

E5. Result rows look the same as list rows, and the first result is highlighted. While the box contains text, its magnifier turns the accent colour and a round clear button (an x) appears at its right end. — `trigger-search-sheet`

E6. Search ignores the mode. In trigger mode it returned non-trigger nodes (for example "Data table" and "Extract from File"), and in next-step mode it returned triggers (for example "Schedule Trigger"). In both modes "Google Sheets" carried the trigger description "Starts the workflow when Google Sheets events occur". — `trigger-search-sheet`, `next-search-sheet`

E7. When nothing matches at a root, the panel shows a centred block: "No results for "<query>"", followed in trigger mode by "Connect to almost any service or API using our Webhook or HTTP Request node" (with both node names underlined as links) and in next-step mode by "…using our HTTP Request node". A footer bar pinned to the bottom reads "Need a native integration?" with a "Suggest a node ↗" link. — `trigger-search-no-results` (L/D), `next-search-no-results` (L/D)

E8. Search inside a built-in category ("Data transformation", "Flow" or "Action in an app") or inside "On app event" puts that category's matches first. A section "Results in other categories" follows, then "More from the community". For example, "filter" inside Data transformation gave "Filter" and "Edit Fields (Set)", and then "If", "Switch", "Execution Data" and the rest under "Results in other categories". — `next-data-transformation-search-filter` (L/D), `trigger-app-event-search-sheet` (L/D)

E9. When nothing in the category matches ("http" inside Flow), the results start directly with "Results in other categories".

E10. Search inside the "AI" view is not scoped to AI. "sheet" and "agent" gave the same list as at the root, with no "Results in other categories" section. — `next-ai-search-sheet` (L/D)

E11. A query that matches nothing inside a category (Flow) shows the same empty state as at the root (E7). — `next-flow-search-no-results` (L)

E12. Search inside an app's action list shows at most one match per section:
- "row" gave "Actions (1)" with "Get row(s) in sheet" and "Triggers (1)" with "On row added";
- "append" gave only "Append row in sheet";
- "record" inside Airtable gave only "Get a record".

A section with no match shows "No matching Triggers." (or "Actions") followed by a "Reset search" link. — `next-app-google-sheets-search-row` (L/D), `next-app-search-no-match` (L/D)

E13. The query is cleared when a sub-view is entered from the results. Going back (Left arrow) restores the earlier query and its results (see G5).

## F. Picking

F1. Picking a node row (Flow → "Filter") closed the panel, added the node connected to the output the panel was opened from, and opened the full-screen node editor (input pane, "Parameters"/"Settings" pane, output pane). The page address gained a node suffix. — `pick-direct-node-editor` (L)

F2. Picking "Trigger manually" closed the panel and added the node without opening the editor. — `pick-trigger-manually-result` (L)

F3. Picking an action (Code → "Code in JavaScript") added a node named after the action ("Code in JavaScript") and opened the editor.

F4. Picking an app under Human review ("Slack") skipped the action list. It added the app's node already set to its send-and-wait action: the node is named "Send a message" with the subtitle "sendAndWait: message", and the "Operation" field shows "Send and Wait for Response". The editor opened. — `pick-human-review-editor` (L)

F5. Picking "AI Agent" added the node with its three connector stubs and opened the editor. — `opener-subnode-connectors` (L)

F6. Picking an app trigger (via "Add another trigger", then "On app event", "Google Sheets" and "On row added") added a node named "Google Sheets Trigger" and opened the editor.

F7. Category rows and built-in app rows never add a node; they open the next list inside the panel and the panel stays open. — `trigger-app-google-sheets`, `next-app-google-sheets`

F8. Picking a verified community row that is not installed opened a view titled "Node details", with a back arrow and a "Docs ↗" link at the right. It showed:
- a large logo, the name and the check-seal;
- the description;
- a meta line with "Verified", a download count and the publisher name;
- the message "Please contact an administrator to install this community node:" followed by an e-mail address;
- previews of the "Triggers (n)" and "Actions (n)" sections;
- a "Report issue" link at the bottom.

No screenshot was kept, because the view shows an e-mail address.

F9. "AI Templates" opened a new browser tab. The panel stayed open on the AI view.

F10. "Message an Agent" opened a sub-view (C28) rather than adding a node.

F11. Dragging a row ("On a schedule") onto the canvas added the node where it was dropped, closed the panel and opened the editor.

F12. When the panel had been opened with "n" and no node was selected, the picked nodes ("Limit", "Sort") were placed on the canvas without any connection. — `next-ai-bottom` (L/D), `opener-sidebar-add-menu` (L): both show the two unconnected nodes

F13. Pressing Enter on a highlighted node row behaves like clicking it: the panel closes and the editor opens (G7).

## G. Keyboard

G1. When the panel opens, the search box has focus and the first row is highlighted. — `kbd-arrowdown-active` (L)

G2. ArrowDown and ArrowUp move the highlight, which wraps round at both ends: Up from the first row goes to the last, and Down from the last goes to the first. Focus stays in the search box throughout. — `kbd-arrowdown-active`

G3. Home and End did not move the highlight.

G4. ArrowRight on a category row or app row opens it, including an app found through search. In the views tested this way ("Data transformation" and the Google Sheets and trigger lists), the highlight then started on the first item, not on a section header.

G5. ArrowLeft in a sub-view goes back one level. On returning, the highlight was on the parent's first row, not on the row that had been opened. When the sub-view had been opened from search results, ArrowLeft brought the query and results back.

G6. ArrowLeft at a root with an empty search box closed the panel. With text in the search box, ArrowLeft did not close it.

G7. Enter on a category row opens it; Enter on a node row adds the node (the panel closes and the editor opens).

G8. Section headers can be highlighted with Up and Down. On a highlighted header, ArrowLeft collapses the section, ArrowRight expands it and Enter toggles it. Items in a collapsed section are skipped by Up and Down.

G9. Escape closed the whole panel at the root, inside sub-views, and also with text in the search box. It never stepped back one level and never just cleared the query.

G10. Tab moved keyboard focus from the search box through the trailing arrow buttons of the rows in order; rows without an arrow were skipped. The highlight did not follow, and Shift+Tab moved back to the search box. While focus was on an arrow button, ArrowDown still moved the highlight, but typed characters did not reach the search box.

G11. Typing a query highlights the first result immediately.

G12. On the canvas, "n" or "N" opens the panel, and Tab shows the shortcut hint (A10, A11).

## H. Layout metrics (light theme, 1440 × 900, numbers only)

H1. The panel is a fixed column 385 px wide along the right edge. It starts directly below the 65 px top bar and runs to the bottom of the viewport; while it is open, the logs bar along the bottom is visible only to the left of the panel. It has a 1 px light-grey line on its left edge and no shadow. Nothing dims the canvas, and the canvas stays clickable (A19). — `next-root`

H2. The header has 16 px padding on all four sides. Its height depends on the view:
- trigger root: 79 px, no fill, no rule;
- next-step root and connector roots: 55 px, light-grey fill, 1 px rule below;
- category and app sub-views: 66 px, grey fill, 1 px rule;
- views with a subtitle: 88 px, no fill, no rule.

— `trigger-root`, `next-root`, `next-data-transformation`, `next-ai`

H3. Header text: titles are 18 px, semibold, on a 22–24 px line. Subtitles are 14 px, regular, muted, on a 19 px line. In sub-views the back button is 34 × 33 px (22 px arrow) at the left padding, and the 20 px category icon starts where the button ends. In those icon headers the title starts 86 px from the panel's left edge. In headers with a subtitle, the title starts 50 px and the subtitle 52 px from the panel's left edge.

H4. The search box is 353 × 40 px, inset 16 px from both sides, with 16 px above and below. It has a 1 px border, 4 px corner radius, a 12 px magnifier and 14 px input text. When focused it has a violet outline. — `next-root`

H5. List rows span the panel's full width (384 px inside the edge line). Each row's content box runs from 16 px inside the left edge to 12 px inside the right edge and has a further 8 px of right padding. Rows have 12 px padding above and below, and the text starts 16 px after the icon. Names are 14 px medium on a roughly 18 px line; descriptions are 12 px regular, muted, on a 16 px line. The trailing arrow is a 16 px icon inside a button 18 px tall. The button's right edge is 20 px from the panel's right edge and the icon's right edge is 26 px from it.

H6. Row heights by kind:
- root and node rows: 60 px with a 1-line description, 76 px with 2 lines, 92 px with 3;
- built-in app rows with no description: 44 px (20 px logo) or 48 px (24 px icon);
- verified community rows: 63, 79 or 95 px, and taller as the description wraps (up to 223 px seen);
- actions and triggers inside an app view: 36 px, with 8 px padding above and below, a 20 px logo, 12 px regular text, and the text starting 32 px from the logo's left edge;
- all-caps resource labels: 28 px including 16 px above the text; the text is 10 px, semibold, letter-spaced 1 px, muted;
- section headers: 35 px with a 14 px semibold label, 16 px left padding, a 16 px chevron at the right and a 1 px rule below.

— `next-root`, `next-app-google-sheets`, `next-data-transformation`

H7. Icon sizes: category rows 26 px; built-in node icons 24 px; app logos 20 px; sub-node logos 20 px on a 40 px round disc; the trigger bolt after a name 10 px; the verification seal 14 px.

H8. Spacing: there is a 16 px gap between the last row of a section and the next section header. Rules between blocks are 1 px, inset 16 px on each side (352 px long). In the next-step root, the rule is drawn at the top of the "Add another trigger" row, which has 12 px of extra space at the top (88 px tall instead of 76). In the AI view, a 16 px gap separates "AI Templates" from the rule below it, and another 16 px gap sits above the rule that precedes "Other AI Nodes".

H9. Row states: the highlighted row has a 2 px accent-orange bar on its left edge, the full height of the row. A hovered row gets the same bar in mid-grey. Neither state changes the row background, and the trailing arrow's colour and opacity did not change on hover. — `next-root-hover` (L), `kbd-arrowdown-active` (L)

H10. Notices: the AI sub-category notice is 353 px wide, has a 7 px amber left bar, 2 px corner radius, 8 px padding and 12 px text. The activation note in app views is a thin-bordered box 46 px tall with 12 px text and a "Learn more" link. — `next-ai-other-language-models`, `trigger-app-google-sheets-actions-expanded`

H11. Tags: "Recommended" is a small outlined tag (10 px text, 4 px corner radius, 99 × 19 px). "Preview" is a filled purple pill (64 × 18 px). "New" is a filled green pill. "Beta" and "Deprecated" are grey tags. — `next-ai`, `opener-subnode-tool`

H12. In dark mode the panel, header band, search box and rows switch to dark surfaces with light text. Layout and positions are unchanged (compare each L/D pair). — e.g. `next-root-dark`, `next-data-transformation-dark`

## Open questions (not observed, and why)

1. Exactly how many items hide the search box: it was missing at 1–6 items and present at 9 or more; no list with 7 or 8 items was available to test.
2. The full ranking rules for search. Only three root queries and a few in-category queries were sampled.
3. Whether the "More from the community" section and the roughly 1,000 verified community rows appear on an instance without internet access. This instance loaded remote logos and community data, and I did not test an offline instance.
4. How an installed community node is listed. None is installed, and the member account cannot install one (F8).
5. Whether owner or admin accounts see different panel contents. Only the member account was used.
6. The destination page of "AI Templates". The new tab was closed immediately and its address was blank when captured.
7. The visual style of a drag in progress (any ghost image or drop marker). The headless capture showed none, so I did not record it.
8. Open, close and view-change animations or their timing. These were not measured.
9. Panel width and header behaviour at other viewport sizes. Only 1440 × 900 was tested.
10. Whether "Add another trigger" could appear without a trigger. The next-step root never appeared in a workflow without one (B19).
11. PageUp and PageDown keys, and search inside "Core" and "Human review". Not tested.
12. Metrics in dark mode. Only screenshots were taken, no measurements.
13. The complete names of the very large lists (C5, C14 "Tools", C16, C26). Only the counts, the composition and the first rows were recorded.
14. Whether the "Press N to browse nodes" hint comes back after "Got it" is pressed. I did not press it, to avoid changing the account's preferences.
15. Why "E2E Test Polling Trigger" appears in Core. It is visible in this instance and its description says it is for testing; its origin cannot be told from the UI.
