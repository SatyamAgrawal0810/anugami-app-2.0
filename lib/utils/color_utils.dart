// lib/utils/color_utils.dart
//
// USAGE — import this anywhere color name → Color is needed:
//
//   import 'package:anu_app/utils/color_utils.dart';
//
//   Color c = AppColorUtils.parse('ruby');        // named color
//   Color c = AppColorUtils.parse('#E0115F');     // hex string
//   Color c = AppColorUtils.parse('unknown');     // → Colors.grey.shade400
//
// Works in:
//   • Cart   (enhanced_cart_item_card.dart)
//   • Product Detail  (variant selector)
//   • Anywhere a colorValue string comes from the backend

import 'package:flutter/material.dart';

abstract class AppColorUtils {
  AppColorUtils._();

  /// Parses a backend color string (name or #hex) into a Flutter [Color].
  /// Falls back to [Colors.grey] shade 400 when unrecognised.
  static Color parse(String? value) {
    if (value == null || value.trim().isEmpty) return Colors.grey.shade400;
    final s = value.trim();

    // ── Hex string ──────────────────────────────────────────────────────────
    if (s.startsWith('#')) {
      try {
        final hex = s.replaceAll('#', '').padLeft(6, '0');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return Colors.grey.shade400;
      }
    }

    // ── Named color map ──────────────────────────────────────────────────────
    return _map[s.toLowerCase()] ?? Colors.grey.shade400;
  }

  static const Map<String, Color> _map = {
    // ── Basic ────────────────────────────────────────────────────────────────
    'black': Colors.black,
    'white': Colors.white,
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'orange': Colors.orange,
    'brown': Colors.brown,
    'gray': Colors.grey,
    'grey': Colors.grey,
    'navy': Color(0xFF000080),
    'teal': Color(0xFF008080),
    'maroon': Color(0xFF800000),
    'olive': Color(0xFF808000),
    'silver': Color(0xFFC0C0C0),

    // ── Metallics ────────────────────────────────────────────────────────────
    'gold': Color(0xFFFFD700),
    'bronze': Color(0xFFCD7F32),
    'copper': Color(0xFFB87333),
    'pearl': Color(0xFFEAEAEA),
    'platinum': Color(0xFFE5E4E2),
    'gunmetal': Color(0xFF2A3439),
    'zinc': Color(0xFFA9A9A9),
    'titanium': Color(0xFF878681),
    'chrome': Color(0xFFDBE4EB),
    'steel': Color(0xFF71797E),

    // ── Neutrals ─────────────────────────────────────────────────────────────
    'beige': Color(0xFFF5F5DC),
    'ivory': Color(0xFFFFFFF0),
    'cream': Color(0xFFFFFDD0),
    'eggshell': Color(0xFFF0EAD6),
    'offwhite': Color(0xFFF8F8FF),
    'almond': Color(0xFFEFDECD),
    'sand': Color(0xFFC2B280),
    'linen': Color(0xFFFAF0E6),
    'bone': Color(0xFFE3DAC9),
    'cotton': Color(0xFFFBFBF9),
    'taupe': Color(0xFF483C32),
    'khaki': Color(0xFFC3B091),
    'tan': Color(0xFFD2B48C),
    'mocha': Color(0xFFA38068),
    'camel': Color(0xFFC19A6B),
    'buff': Color(0xFFF0DC82),
    'chamois': Color(0xFFFADFA8),
    'sepia': Color(0xFF704214),
    'umber': Color(0xFF635147),
    'ecru': Color(0xFFC2B280),
    'fawn': Color(0xFFE5AA70),
    'parchment': Color(0xFFF1E9D2),
    'oyster': Color(0xFFCFC4A6),
    'bisque': Color(0xFFFFE4C4),
    'stone': Color(0xFF928E85),
    'greige': Color(0xFFA09998),
    'chalk': Color(0xFFF5F5F5),

    // ── Reds ─────────────────────────────────────────────────────────────────
    'crimson': Color(0xFFDC143C),
    'ruby': Color(0xFFE0115F),
    'wine': Color(0xFF722F37),
    'burgundy': Color(0xFF800020),
    'cherry': Color(0xFFDE3163),
    'rose': Color(0xFFFF007F),
    'garnet': Color(0xFF733635),
    'vermilion': Color(0xFFE34234),
    'tomato': Color(0xFFFF6347),
    'raspberry': Color(0xFFE30B5C),
    'cranberry': Color(0xFF9F000F),
    'carmine': Color(0xFF960018),
    'brick': Color(0xFFB22222),
    'coral': Color(0xFFFF7F50),
    'salmon': Color(0xFFFA8072),
    'blood': Color(0xFF8A0303),
    'sangria': Color(0xFF92000A),
    'russet': Color(0xFF80461B),
    'cinnabar': Color(0xFFE44D2E),
    'auburn': Color(0xFFA52A2A),
    'scarlet': Color(0xFFFF2400),
    'rust': Color(0xFFB7410E),
    'terracotta': Color(0xFFE2725B),
    'rosewood': Color(0xFF65000B),
    'cardinal': Color(0xFFC41E3A),
    'redwood': Color(0xFFA45A52),
    'strawberry': Color(0xFFFC5A8D),
    'cerise': Color(0xFFDE3163),
    'claret': Color(0xFF7F1734),
    'mahogany': Color(0xFFC04000),

    // ── Oranges ──────────────────────────────────────────────────────────────
    'tangerine': Color(0xFFF28500),
    'amber': Color(0xFFFFBF00),
    'apricot': Color(0xFFFBCEB1),
    'peach': Color(0xFFFFDAB9),
    'persimmon': Color(0xFFEC5800),
    'honey': Color(0xFFF4A460),
    'marigold': Color(0xFFEAA221),
    'cinnamon': Color(0xFFD2691E),
    'pumpkin': Color(0xFFFF7518),
    'saffron': Color(0xFFF4C430),
    'ochre': Color(0xFFCC7722),
    'carrot': Color(0xFFED9121),
    'sienna': Color(0xFFA0522D),
    'mandarin': Color(0xFFF89406),

    // ── Yellows ──────────────────────────────────────────────────────────────
    'lemon': Color(0xFFFFF700),
    'mustard': Color(0xFFFFDB58),
    'canary': Color(0xFFFFFF99),
    'citrine': Color(0xFFE4D00A),
    'banana': Color(0xFFFCF4A3),
    'bumblebee': Color(0xFFFCE205),
    'flax': Color(0xFFEEDC82),
    'sunshine': Color(0xFFFDFD96),
    'goldenrod': Color(0xFFDAA520),
    'butterscotch': Color(0xFFE59E1F),
    'dijon': Color(0xFFC49102),

    // ── Greens ───────────────────────────────────────────────────────────────
    'emerald': Color(0xFF50C878),
    'jade': Color(0xFF00A86B),
    'mint': Color(0xFF98FB98),
    'sage': Color(0xFFBCB88A),
    'moss': Color(0xFF8A9A5B),
    'hunter': Color(0xFF355E3B),
    'forest': Color(0xFF0B6623),
    'avocado': Color(0xFF568203),
    'lime': Color(0xFF00FF00),
    'pistachio': Color(0xFF93C572),
    'seafoam': Color(0xFF71EEB8),
    'chartreuse': Color(0xFF7FFF00),
    'malachite': Color(0xFF0BDA51),
    'spruce': Color(0xFF008080),
    'juniper': Color(0xFF6D9292),
    'basil': Color(0xFF579229),
    'fern': Color(0xFF4F7942),
    'cactus': Color(0xFF5B6C5D),
    'pine': Color(0xFF01796F),
    'shamrock': Color(0xFF45CEA2),
    'eucalyptus': Color(0xFF44D7A8),
    'evergreen': Color(0xFF05472A),
    'artichoke': Color(0xFF8F9779),
    'tea': Color(0xFFD0F0C0),
    'matcha': Color(0xFFBEC187),
    'celadon': Color(0xFFACE1AF),
    'army': Color(0xFF4B5320),

    // ── Blues ────────────────────────────────────────────────────────────────
    'azure': Color(0xFF007FFF),
    'cobalt': Color(0xFF0047AB),
    'lapis': Color(0xFF26619C),
    'cerulean': Color(0xFF007BA7),
    'sapphire': Color(0xFF0F52BA),
    'midnightblue': Color(0xFF191970),
    'royalblue': Color(0xFF4169E1),
    'periwinkle': Color(0xFFCCCCFF),
    'babyblue': Color(0xFF89CFF0),
    'skyblue': Color(0xFF87CEEB),
    'cornflower': Color(0xFF6495ED),
    'steelblue': Color(0xFF4682B4),
    'powderblue': Color(0xFFB0E0E6),
    'aqua': Color(0xFF00FFFF),
    'cyan': Color(0xFF00FFFF),
    'turquoise': Color(0xFF40E0D0),
    'aquamarine': Color(0xFF7FFFD4),
    'glacier': Color(0xFFB2FFFF),
    'aegean': Color(0xFF1E456E),
    'beryl': Color(0xFF0D98BA),
    'celeste': Color(0xFFB2FFFF),
    'chambray': Color(0xFF6D92A1),
    'denim': Color(0xFF1560BD),
    'indigo': Color(0xFF4B0082),
    'ultramarine': Color(0xFF120A8F),
    'slate': Color(0xFF708090),

    // ── Purples ──────────────────────────────────────────────────────────────
    'lavender': Color(0xFFE6E6FA),
    'violet': Color(0xFFEE82EE),
    'amethyst': Color(0xFF9966CC),
    'plum': Color(0xFF8E4585),
    'orchid': Color(0xFFDA70D6),
    'mulberry': Color(0xFFC54B8C),
    'heliotrope': Color(0xFFDF73FF),
    'wisteria': Color(0xFFC9A0DC),
    'fuchsia': Color(0xFFFF00FF),
    'magenta': Color(0xFFFF00FF),
    'mauve': Color(0xFFE0B0FF),
    'lilac': Color(0xFFC8A2C8),
    'grape': Color(0xFF6F2DA8),
    'eggplant': Color(0xFF614051),
    'byzantium': Color(0xFF702963),
    'aubergine': Color(0xFF472D47),
    'thistle': Color(0xFFD8BFD8),

    // ── Browns ───────────────────────────────────────────────────────────────
    'chocolate': Color(0xFF7B3F00),
    'coffee': Color(0xFF6F4E37),
    'chestnut': Color(0xFF954535),
    'walnut': Color(0xFF773F1A),
    'pecan': Color(0xFF4A2511),
    'hickory': Color(0xFF9D7B58),
    'toffee': Color(0xFFA67B5B),
    'bistre': Color(0xFF3D2B1F),
    'bark': Color(0xFF5D4037),
    'toast': Color(0xFFA38064),
    'espresso': Color(0xFF3C2414),
    'cognac': Color(0xFF834A32),
    'tortilla': Color(0xFF997950),
    'hazel': Color(0xFFAE7250),

    // ── Grays ────────────────────────────────────────────────────────────────
    'charcoal': Color(0xFF36454F),
    'pewter': Color(0xFF899499),
    'ash': Color(0xFFB2BEB5),
    'smoke': Color(0xFF738276),
    'mist': Color(0xFF88ACB8),
    'dove': Color(0xFF848484),
    'nickel': Color(0xFF727472),
    'lead': Color(0xFF43464B),
    'onyx': Color(0xFF353839),
    'shadow': Color(0xFF403F4C),
    'graphite': Color(0xFF2E3441),
    'obsidian': Color(0xFF000000),
    'ebony': Color(0xFF555D50),
    'concrete': Color(0xFF95A5A6),
    'storm': Color(0xFF494F5C),

    // ── Pinks ────────────────────────────────────────────────────────────────
    'blush': Color(0xFFDE5D83),
    'carnation': Color(0xFFFFA6C9),
    'bubblegum': Color(0xFFFFC1CC),
    'flamingo': Color(0xFFFC8EAC),
    'neon': Color(0xFFFF6EC7),
    'hotpink': Color(0xFFFF69B4),
    'deeppink': Color(0xFFFF1493),
    'ballet': Color(0xFFF8C8DC),
    'rosewater': Color(0xFFFAD6D6),
    'peony': Color(0xFFE082A8),
    'dustyrose': Color(0xFFDCAE96),
    'watermelon': Color(0xFFFC6C85),

    // ── Specialty ────────────────────────────────────────────────────────────
    'opal': Color(0xFFA8C3BC),
    'topaz': Color(0xFFFFC87C),
    'jet': Color(0xFF343434),
    'amaranth': Color(0xFFE52B50),
    'sable': Color(0xFF492927),
    'citron': Color(0xFF9FA91F),
    'puce': Color(0xFFCC8899),
    'alabaster': Color(0xFFEDEAE0),
    'jonquil': Color(0xFFF4CA16),
    'verdigris': Color(0xFF43B3AE),
    'vermillion': Color(0xFFE34234),
    'titian': Color(0xFFE08D3C),
    'damson': Color(0xFF722F37),
    'raven': Color(0xFF2E2E2E),

    // ── Modern Fashion ───────────────────────────────────────────────────────
    'millennial': Color(0xFFEADCD2),
    'dustyblue': Color(0xFF8AABBD),
    'dustymint': Color(0xFFB0C4BB),
    'mango': Color(0xFFFF8243),
    'sunset': Color(0xFFFAD6A5),
    'sunrise': Color(0xFFFFCBA4),
    'vintage': Color(0xFFC0B9AC),
    'shell': Color(0xFFF8E0D5),
  };
}
