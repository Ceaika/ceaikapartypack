global function PH_SettingsInit
void function PH_SettingsInit()
{
    ModSettings_AddModTitle("Prop Hunt")
    ModSettings_AddModCategory("Keyboard / mouse - changes apply immediately")
    ModSettings_AddEnumSetting("ph_bind_reroll_key","Reroll disguise",PH_KeyLabels())
    ModSettings_AddEnumSetting("ph_bind_decoy_key","Place decoy",PH_KeyLabels())
    ModSettings_AddEnumSetting("ph_bind_lock_key","Lock prop rotation",PH_KeyLabels())
    ModSettings_AddEnumSetting("ph_bind_freeze_key","Freeze / unfreeze",PH_KeyLabels())
    ModSettings_AddEnumSetting("ph_bind_taunt_g_key","Taunt (make your sound)",PH_KeyLabels())
    ModSettings_AddModCategory("Controller - use a different button for each action")
    ModSettings_AddEnumSetting("ph_bind_reroll_pad","Reroll disguise",PH_PadLabels())
    ModSettings_AddEnumSetting("ph_bind_decoy_pad","Place decoy",PH_PadLabels())
    ModSettings_AddEnumSetting("ph_bind_lock_pad","Lock prop rotation",PH_PadLabels())
    ModSettings_AddEnumSetting("ph_bind_freeze_pad","Freeze / unfreeze",PH_PadLabels())
    ModSettings_AddEnumSetting("ph_bind_taunt_g_pad","Taunt (make your sound)",PH_PadLabels())
}
