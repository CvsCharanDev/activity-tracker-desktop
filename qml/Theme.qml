pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ── Active Theme State (Persisted) ────────────────────────────────────────
    property bool isDark: true

    function toggleTheme() {
        isDark = !isDark
    }

    // ── Architectural Monochrome Surfaces (Linear / Raycast / Slate Base) ─────
    readonly property color bgCanvas:         isDark ? "#0C0D0E" : "#FBFBFB"
    readonly property color surfaceNav:       isDark ? "#121316" : "#FFFFFF"
    readonly property color surfaceSidebar:   isDark ? "#0F1012" : "#F8F9FA"
    readonly property color surfaceCard:      isDark ? "#16171B" : "#FFFFFF"
    readonly property color surfaceCardHover: isDark ? "#1F2026" : "#F3F4F6"
    readonly property color surfaceInput:     isDark ? "#131417" : "#FFFFFF"
    readonly property color surfaceBadge:     isDark ? "#1E2025" : "#F1F3F5"

    // ── Structural Borders ────────────────────────────────────────────────────
    readonly property color borderDefault:    isDark ? "#26282E" : "#E5E7EB"
    readonly property color borderSubtle:     isDark ? "#1B1C20" : "#F0F2F5"
    readonly property color borderFocus:      isDark ? "#3B82F6" : "#2563EB"

    // ── Typography Hierarchy (Maximum Contrast & Readability) ────────────────
    readonly property color textPrimary:      isDark ? "#F8FAFC" : "#0F172A"
    readonly property color textSecondary:    isDark ? "#94A3B8" : "#475569"
    readonly property color textMuted:        isDark ? "#64748B" : "#94A3B8"

    // ── Dedicated Semantic Accents (Strict Single-Purpose Assignment) ─────────
    // 1. In-Progress & Active Focus Lifecycle (Electric Blue)
    readonly property color accentBlue:       isDark ? "#3B82F6" : "#2563EB"
    readonly property color accentBlueBg:     isDark ? "#13233C" : "#EFF6FF"
    readonly property color accentBlueBorder: isDark ? "#1D3B66" : "#BFDBFE"

    // 2. Completed / Success Lifecycle (Emerald Green)
    readonly property color accentGreen:      isDark ? "#10B981" : "#059669"
    readonly property color accentGreenBg:    isDark ? "#0A281E" : "#ECFDF5"
    readonly property color accentGreenBorder:isDark ? "#0F5132" : "#A7F3D0"

    // 3. Urgent / Critical Alert / Overdue (Rose Red)
    readonly property color accentRose:       isDark ? "#F43F5E" : "#E11D48"
    readonly property color accentRoseBg:     isDark ? "#2D0D15" : "#FFF1F2"
    readonly property color accentRoseBorder: isDark ? "#581222" : "#FECDD3"

    // 4. Warning / Near-Deadline Countdown (Amber)
    readonly property color accentAmber:      isDark ? "#F59E0B" : "#D97706"
    readonly property color accentAmberBg:    isDark ? "#2E1A05" : "#FFFBEB"
    readonly property color accentAmberBorder:isDark ? "#573007" : "#FDE68A"

    // 5. Overtime & Extra Extensions ONLY (Violet / Purple)
    readonly property color accentPurple:     isDark ? "#A855F7" : "#7C3AED"
    readonly property color accentPurpleBg:   isDark ? "#260E36" : "#FAF5FF"
    readonly property color accentPurpleBorder:isDark ?"#4C1D6B" : "#DDD6FE"

    // 6. Destructive Actions (Pure Red)
    readonly property color accentRed:        isDark ? "#EF4444" : "#DC2626"
    readonly property color accentRedBg:      isDark ? "#2D0A0A" : "#FEF2F2"
    readonly property color accentRedBorder:  isDark ? "#581111" : "#FECACA"

    // ── Semantic Priority Matrix (Linear Standard: Only Urgent & High scream) ──
    function priorityCode(p) {
        switch(p) {
        case "Urgent": case "P0": return "P0"
        case "High":   case "P1": return "P1"
        case "Low":    case "P3": case "P4": return "P3"
        default:                  return "P2"
        }
    }

    function priorityColor(p) {
        switch(p) {
        case "Urgent": case "P0": return isDark ? "#F43F5E" : "#E11D48" // Rose Alert
        case "High":   case "P1": return isDark ? "#F59E0B" : "#D97706" // Amber Warning
        case "Low":    case "P3": case "P4": return isDark ? "#64748B" : "#94A3B8" // Low Muted
        default:                  return isDark ? "#94A3B8" : "#64748B" // P2 Normal Slate
        }
    }

    function priorityBg(p) {
        if (isDark) {
            switch(p) {
            case "Urgent": case "P0": return "#2D0D15"
            case "High":   case "P1": return "#2E1A05"
            default:                  return "#1A1C21"
            }
        } else {
            switch(p) {
            case "Urgent": case "P0": return "#FFF1F2"
            case "High":   case "P1": return "#FFFBEB"
            default:                  return "#F1F5F9"
            }
        }
    }

    function priorityBorder(p) {
        if (isDark) {
            switch(p) {
            case "Urgent": case "P0": return "#581222"
            case "High":   case "P1": return "#573007"
            default:                  return "#272930"
            }
        } else {
            switch(p) {
            case "Urgent": case "P0": return "#FECDD3"
            case "High":   case "P1": return "#FDE68A"
            default:                  return "#E2E8F0"
            }
        }
    }
}
