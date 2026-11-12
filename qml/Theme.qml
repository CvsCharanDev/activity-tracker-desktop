pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ── Active Theme State (Persisted) ────────────────────────────────────────
    property bool isDark: true

    function toggleTheme() {
        isDark = !isDark
    }

    // ── Surfaces & Canvases (Linear / Vercel Pro Grade Palette) ──────────────
    readonly property color bgCanvas:         isDark ? "#0A0E17" : "#F8FAFC"
    readonly property color surfaceNav:       isDark ? "#0F1624" : "#FFFFFF"
    readonly property color surfaceSidebar:   isDark ? "#0C111D" : "#F8FAFC"
    readonly property color surfaceCard:      isDark ? "#131B2A" : "#FFFFFF"
    readonly property color surfaceCardHover: isDark ? "#1A2438" : "#F1F5F9"
    readonly property color surfaceInput:     isDark ? "#0D1320" : "#FFFFFF"
    readonly property color surfaceBadge:     isDark ? "#162033" : "#F1F5F9"

    // ── Borders ───────────────────────────────────────────────────────────────
    readonly property color borderDefault:    isDark ? "#1E2A3F" : "#E2E8F0"
    readonly property color borderSubtle:     isDark ? "#162033" : "#F1F5F9"
    readonly property color borderFocus:      isDark ? "#38BDF8" : "#0284C7"

    // ── Text Hierarchy ────────────────────────────────────────────────────────
    readonly property color textPrimary:      isDark ? "#F8FAFC" : "#0F172A"
    readonly property color textSecondary:    isDark ? "#94A3B8" : "#475569"
    readonly property color textMuted:        isDark ? "#64748B" : "#94A3B8"

    // ── Semantic Accents: Blue (Default / Active / Work) ──────────────────────
    readonly property color accentBlue:       isDark ? "#38BDF8" : "#0284C7"
    readonly property color accentBlueBg:     isDark ? "#0E2238" : "#F0F9FF"
    readonly property color accentBlueBorder: isDark ? "#163E66" : "#BAE6FD"

    // ── Semantic Accents: Green (Completed / Success / Personal) ──────────────
    readonly property color accentGreen:      isDark ? "#10B981" : "#059669"
    readonly property color accentGreenBg:    isDark ? "#062E20" : "#ECFDF5"
    readonly property color accentGreenBorder:isDark ? "#0D4D33" : "#A7F3D0"

    // ── Semantic Accents: Amber (Learning / In-Progress / Notice) ─────────────
    readonly property color accentAmber:      isDark ? "#F59E0B" : "#D97706"
    readonly property color accentAmberBg:    isDark ? "#261B06" : "#FFFBEB"
    readonly property color accentAmberBorder:isDark ? "#593608" : "#FDE68A"

    // ── Semantic Accents: Purple (Time / Extensions / Metrics) ────────────────
    readonly property color accentPurple:     isDark ? "#A855F7" : "#7C3AED"
    readonly property color accentPurpleBg:   isDark ? "#221136" : "#FAF5FF"
    readonly property color accentPurpleBorder:isDark ?"#4C1D78" : "#DDD6FE"

    // ── Semantic Accents: Red (Delete / Destructive / Urgent) ─────────────────
    readonly property color accentRed:        isDark ? "#EF4444" : "#DC2626"
    readonly property color accentRedBg:      isDark ? "#281014" : "#FEF2F2"
    readonly property color accentRedBorder:  isDark ? "#5C171F" : "#FECACA"

    // ── Semantic Priority Matrix (P0 Urgent, P1 High, P2 Medium, P3 Low) ─────
    function priorityCode(p) {
        switch(p) {
        case "Urgent": case "P0": return "P0"
        case "High":   case "P1": return "P1"
        case "Low":    case "P3": case "P4": return "P3"
        default:                  return "P2" // Medium / P2
        }
    }

    function priorityColor(p) {
        switch(p) {
        case "Urgent": case "P0": return isDark ? "#F87171" : "#DC2626"
        case "High":   case "P1": return isDark ? "#FB923C" : "#EA580C"
        case "Low":    case "P3": case "P4": return isDark ? "#94A3B8" : "#64748B"
        default:                  return isDark ? "#38BDF8" : "#0284C7" // Medium / P2
        }
    }

    function priorityBg(p) {
        if (isDark) {
            switch(p) {
            case "Urgent": case "P0": return "#321217"
            case "High":   case "P1": return "#2C1708"
            case "Low":    case "P3": case "P4": return "#1E293B"
            default:                  return "#0C2340"
            }
        } else {
            switch(p) {
            case "Urgent": case "P0": return "#FEF2F2"
            case "High":   case "P1": return "#FFF7ED"
            case "Low":    case "P3": case "P4": return "#F1F5F9"
            default:                  return "#F0F9FF"
            }
        }
    }

    function priorityBorder(p) {
        if (isDark) {
            switch(p) {
            case "Urgent": case "P0": return "#991B1B"
            case "High":   case "P1": return "#9A3412"
            case "Low":    case "P3": case "P4": return "#334155"
            default:                  return "#0369A1"
            }
        } else {
            switch(p) {
            case "Urgent": case "P0": return "#FECACA"
            case "High":   case "P1": return "#FED7AA"
            case "Low":    case "P3": case "P4": return "#CBD5E1"
            default:                  return "#BAE6FD"
            }
        }
    }
}
