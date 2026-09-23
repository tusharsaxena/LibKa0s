-- testkit/prose_lists.lua — the lists `test_prose.lua` reads, peeled out of it at kit revision 26.
--
-- WHY A SEPARATE FILE. `test_prose.lua` reached 1499 lines at kit revision 25, one under
-- `layout-§1`'s cap, and the lists are the part of it that grows: a spelling localization-5 adds
-- arrives here on the next sync, and so does a frozen-bundle folder the published exclusion list
-- gains. Kept apart, that growth lands in a file of data rather than in the gate. Moving them
-- changes no behavior: the same tables, the same order, the same counts.
--
-- It quotes every forbidden spelling in order to forbid it, which is localization-5's fourth
-- exclusion: the gate's own copy of the lists. `test_prose.lua` loads it by path from its own
-- folder, and nothing else reads it.

-- ---------------------------------------------------------------------------
-- The published lists (localization-5), copied whole
-- ---------------------------------------------------------------------------

-- localization-5 · US English is the source dialect. Copy BOTH lists whole.
-- BRITISH: lowercase substrings, matched case-insensitively.
-- ALLOWED: correct US words that contain a BRITISH substring; removed as WHOLE WORDS first.

local BRITISH = {
    -- -our → -or
    "colour", "behaviour", "favour", "honour", "neighbour", "armour", "flavour",
    "labour", "rumour", "humour", "endeavour", "rigour", "vigour", "saviour",
    -- -re → -er
    "centre", "centring", "metre", "fibre", "calibre", "theatre", "manoeuvre",
    -- -ce → -se
    "defence", "licence", "offence", "pretence", "practis",
    -- -ise / -isation → -ize / -ization, and the -yse verbs
    "initialis", "normalis", "generalis", "specialis", "optimis", "customis",
    "serialis", "summaris", "utilis", "organis", "authoris", "prioritis",
    "alphabetis", "categoris", "sanitis", "visualis", "minimis", "maximis",
    "itemis", "randomis", "tokenis", "capitalis", "localis", "modularis",
    "standardis", "memois", "recognis", "analys", "paralys", "synthesis",
    "emphasis",
    -- a doubled consonant before a suffix, where US English keeps one
    "cancelled", "cancelling", "cancellable", "labelled", "labelling",
    "travelled", "travelling", "modelled", "modelling", "signalled",
    "signalling", "levelled", "levelling", "fuelled", "fuelling", "totalled",
    "totalling", "fulfil",
    -- -ogue → -og
    "catalogue", "dialogue", "analogue",
    -- no family, just British
    "grey", "artefact", "whilst", "amongst", "learnt", "ageing", "enquir",
    "acknowledgement", "judgement", "sceptic", "mould", "sulphur", "programme",
}

local ALLOWED = {
    "analysis", "analyses", "analyst", "analysts",
    "organism", "organisms", "organist",
    "specialist", "specialists", "generalist", "generalists",
    "optimism", "optimist", "optimists", "optimistic", "optimistically",
    "paralysis", "paralyses", "synthesis", "syntheses", "emphasis", "emphases",
    "fulfill", "fulfills", "fulfilled", "fulfilling", "fulfillment",
    "programmer", "programmers", "programmed",
}

-- The published block is 91 substrings and 30 allowances. The counts are a tripwire, not a proof —
-- a copy that drops one entry and invents another passes them — but the failure mode they catch is
-- the one that actually happens, which is a list arriving truncated or half-pasted.
local PUBLISHED_BRITISH, PUBLISHED_ALLOWED = 91, 30

-- ---------------------------------------------------------------------------
-- What is scanned, and what is not: the published folder exclusions
-- ---------------------------------------------------------------------------

-- The exclusions localization-5 names, and only those. Every one is a directory or a file rather
-- than a pattern, so the list cannot quietly grow by widening a regex: vendored code the consumer
-- MUST NOT edit (`libs/`, `tests/_kit/`), frozen dated bundles, which record what a tool said on
-- the day rather than authored prose, `locales/enGB.lua`, which is what a British locale file is
-- for, and the gate itself, which quotes every forbidden spelling in order to forbid it.
local SKIPPED_DIRS = {
    "libs/", "Libs/", "tests/_kit/",
    "docs/audits/", "docs/automated-tests/", "docs/perf-analysis/",
    "docs/reviews/", "docs/revendor/",
}

return {
    BRITISH = BRITISH,
    ALLOWED = ALLOWED,
    PUBLISHED_BRITISH = PUBLISHED_BRITISH,
    PUBLISHED_ALLOWED = PUBLISHED_ALLOWED,
    SKIPPED_DIRS = SKIPPED_DIRS,
}
