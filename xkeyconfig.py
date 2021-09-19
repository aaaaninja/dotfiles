import re
from xkeysnail.transform import *

define_modmap({
    Key.CAPSLOCK: Key.LEFT_CTRL
})

define_keymap(None, {
#===================================tekito===================================
    K("C-h"): K("BACKSPACE"),
#===================================1段===================================
    K("GRAVE"): K("Shift-LEFT_BRACE"),
    K("Shift-GRAVE"): K("Shift-EQUAL"),

#    K("Shift-KEY_1"): K("Shift-KEY_1"),
    K("Shift-KEY_2"): K("LEFT_BRACE"),
#    K("Shift-KEY_3"): K("Shift-KEY_3"),
#    K("Shift-KEY_4"): K("Shift-KEY_4"),
#    K("Shift-KEY_5"): K("Shift-KEY_5"),
    K("Shift-KEY_6"): K("EQUAL"),
    K("Shift-KEY_7"): K("Shift-KEY_6"),
    K("Shift-KEY_8"): K("Shift-APOSTROPHE"),
    K("Shift-KEY_9"): K("Shift-KEY_8"),
    K("Shift-KEY_0"): K("Shift-KEY_9"),

#    K("MINUS"): K("MINUS"),
    K("Shift-MINUS"): K("Shift-RO"),

    K("EQUAL"): K("Shift-MINUS"),
    K("Shift-EQUAL"): K("Shift-SEMICOLON"),

#    K("YEN"): K("Shift-KEY_9"),
#    K("Shift-YEN"): K("Shift-KEY_9"),
#===================================2段===================================
    K("LEFT_BRACE"): K("RIGHT_BRACE"),
    K("Shift-LEFT_BRACE"): K("Shift-RIGHT_BRACE"),

    K("RIGHT_BRACE"): K("BACKSLASH"),
    K("Shift-RIGHT_BRACE"): K("Shift-BACKSLASH"),
#===================================3段===================================
#    K("SEMICOLON"): K("SEMICOLON"),
    K("Shift-SEMICOLON"): K("APOSTROPHE"),

    K("APOSTROPHE"): K("Shift-KEY_7"),
    K("Shift-APOSTROPHE"): K("Shift-KEY_2"),

#    K("BACKSLASH"): K("Shift-MINUS"),
#===================================4段===================================
#    K("EQUAL"): K("Shift-MINUS"),

    K("RM-space"): launch(["copyq toggle"]),

})

#define_multipurpose_modmap({
#    Key.CAPSLOCK: [Key.ESC, Key.CAPSLOCK],
##    Key.MUHENKAN: [Key.MUHENKAN, Key.LEFT_ALT],
##    Key.HENKAN: [Key.BACKSPACE, Key.RIGHT_CTRL]
#})
