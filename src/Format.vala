namespace Notejot {
    public enum Format {
        BOLD,
        ITALIC,
        UNDERLINE,
        STRIKETHROUGH
    }

    public struct FormatBlock {
        public int start;
        public int end;
        public Format format;
    }

    public string format_to_string(Format fmt) {
        switch (fmt) {
            case Format.BOLD:
                return "|";
            case Format.ITALIC:
                return "*";
            case Format.UNDERLINE:
                return "_";
            case Format.STRIKETHROUGH:
                return "~";
            default:
                assert_not_reached();
        }
    }

    public Format string_to_format(string wrap) {
        switch (wrap) {
            case "|":
                return Format.BOLD;
            case "*":
                return Format.ITALIC;
            case "_":
                return Format.UNDERLINE;
            case "~":
                return Format.STRIKETHROUGH;
            default:
                assert_not_reached();
        }
    }
}
