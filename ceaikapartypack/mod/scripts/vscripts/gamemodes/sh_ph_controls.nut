global function PH_KeyLabels
global function PH_PadLabels
global function PH_BindingLabel
global function PH_BindingIndex
#if CLIENT
global function PH_KeyCodes
global function PH_PadCodes
#endif
array<string> function PH_KeyLabels() { return ["Unbound", "R", "Q", "F", "E", "A", "B", "C", "D", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "Space", "LShift", "LCtrl", "LAlt", "Mouse3", "Mouse4", "Mouse5"]; }
array<string> function PH_PadLabels() { return ["Unbound", "D-pad Left", "D-pad Up", "D-pad Down", "D-pad Right", "A", "B", "X", "Y", "LB", "RB"]; }
int function PH_BindingIndex(string action,bool pad)
{

    string name=action=="taunt" ? "taunt_g" : action
    int value=GetConVarInt("ph_bind_"+name+(pad ? "_pad" : "_key"))
    int count=pad ? PH_PadLabels().len() : PH_KeyLabels().len()
    return value>=0 && value<count ? value : 0
}
string function PH_BindingLabel(string action)
{
    return PH_KeyLabels()[PH_BindingIndex(action,false)]+" / "+PH_PadLabels()[PH_BindingIndex(action,true)]
}
#if CLIENT
array<int> function PH_KeyCodes() { return [-1, KEY_R, KEY_Q, KEY_F, KEY_E, KEY_A, KEY_B, KEY_C, KEY_D, KEY_G, KEY_H, KEY_I, KEY_J, KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P, KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z, KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_SPACE, KEY_LSHIFT, KEY_LCONTROL, KEY_LALT, MOUSE_MIDDLE, MOUSE_4, MOUSE_5]; }
array<int> function PH_PadCodes() { return [-1, BUTTON_DPAD_LEFT, BUTTON_DPAD_UP, BUTTON_DPAD_DOWN, BUTTON_DPAD_RIGHT, BUTTON_A, BUTTON_B, BUTTON_X, BUTTON_Y, BUTTON_SHOULDER_LEFT, BUTTON_SHOULDER_RIGHT]; }
#endif
