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
    readonly property color bgCanvas:         isDark ? "#09090B" : "#F4F5F7"
    readonly property color surfaceNav:       isDark ? "#111114" : "#FFFFFF"
    readonly property color surfaceSidebar:   isDark ? "#0F0F12" : "#FAFAFA"
    readonly property color surfaceCard:      isDark ? "#18181B" : "#FFFFFF"
    readonly property color surfaceCardHover: isDark ? "#222226" : "#F8F9FA"
    readonly property color surfaceInput:     isDark ? "#121215" : "#FFFFFF"
    readonly property color surfaceBadge:     isDark ? "#202024" : "#EAECEF"

    // ── Borders ───────────────────────────────────────────────────────────────
    readonly property color borderDefault:    isDark ? "#27272A" : "#E2E4E8"
    readonly property color borderSubtle:     isDark ? "#1F1F23" : "#EDEFF2"
    readonly property color borderFocus:      isDark ? "#3B82F6" : "#2563EB"

    // ── Text Hierarchy ────────────────────────────────────────────────────────
    readonly property color textPrimary:      isDark ? "#F4F4F5" : "#111827"
    readonly property color textSecondary:    isDark ? "#A1A1AA" : "#4B5563"
    readonly property color textMuted:        isDark ? "#71717A" : "#9CA3AF"

    // ── Semantic Accents: Blue (Default / Active / Work) ──────────────────────
    readonly property color accentBlue:       isDark ? "#3B82F6" : "#2563EB"
    readonly property color accentBlueBg:     isDark ? "#172554" : "#EFF6FF"
    readonly property color accentBlueBorder: isDark ? "#1E40AF" : "#BFDBFE"

    // ── Semantic Accents: Green (Completed / Success / Personal) ──────────────
    readonly property color accentGreen:      isDark ? "#10B981" : "#059669"
    readonly property color accentGreenBg:    isDark ? "#064E3B" : "#ECFDF5"
    readonly property color accentGreenBorder:isDark ? "#047857" : "#A7F3D0"

    // ── Semantic Accents: Amber (Learning / In-Progress / Notice) ─────────────
    readonly property color accentAmber:      isDark ? "#F59E0B" : "#D97706"
    readonly property color accentAmberBg:    isDark ? "#451A03" : "#FFFBEB"
    readonly property color accentAmberBorder:isDark ? "#78350F" : "#FDE68A"

    // ── Semantic Accents: Purple (Time / Extensions / Metrics) ────────────────
    readonly property color accentPurple:     isDark ? "#A855F7" : "#7C3AED"
    readonly property color accentPurpleBg:   isDark ? "#3B0764" : "#FAF5FF"
    readonly property color accentPurpleBorder:isDark ?"#6B21A8" : "#DDD6FE"

    // ── Semantic Accents: Red (Delete / Destructive / Urgent) ─────────────────
    readonly property color accentRed:        isDark ? "#EF4444" : "#DC2626"
    readonly property color accentRedBg:      isDark ? "#450A0A" : "#FEF2F2"
    readonly property color accentRedBorder:  isDark ? "#7F1D1D" : "#FECACA"

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
        case "Urgent": case "P0": return isDark ? "#EF4444" : "#DC2626"
        case "High":   case "P1": return isDark ? "#F97316" : "#EA580C"
        case "Low":    case "P3": case "P4": return isDark ? "#A1A1AA" : "#6B7280"
        default:                  return isDark ? "#3B82F6" : "#2563EB" // Medium / P2
        }
    }

    function priorityBg(p) {
        if (isDark) {
            switch(p) {
            case "Urgent": case "P0": return "#321217"
            case "High":   case "P1": return "#2C1708"
            case "Low":    case "P3": case "P4": return "#202024"
            default:                  return "#172554"
            }
        } else {
            switch(p) {
            case "Urgent": case "P0": return "#FEF2F2"
            case "High":   case "P1": return "#FFF7ED"
            case "Low":    case "P3": case "P4": return "#F3F4F6"
            default:                  return "#EFF6FF"
            }
        }
    }

    function priorityBorder(p) {
        if (isDark) {
            switch(p) {
            case "Urgent": case "P0": return "#7F1D1D"
            case "High":   case "P1": return "#7C2D12"
            case "Low":    case "P3": case "P4": return "#27272A"
            default:                  return "#1E40AF"
            }
        } else {
            switch(p) {
            case "Urgent": case "P0": return "#FECACA"
            case "High":   case "P1": return "#FED7AA"
            case "Low":    case "P3": case "P4": return "#E5E7EB"
            default:                  return "#BFDBFE"
            }
        }
    }
}
