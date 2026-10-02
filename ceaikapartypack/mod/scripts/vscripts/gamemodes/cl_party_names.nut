global function PartyName_Image
global function PartyName_Aspect

asset function PartyName_Image( string key )
{
    switch ( key )
    {
        case "mp_angel_city": return $"rui/ceaika/name_mp_angel_city"
        case "mp_black_water_canal": return $"rui/ceaika/name_mp_black_water_canal"
        case "mp_coliseum": return $"rui/ceaika/name_mp_coliseum"
        case "mp_coliseum_column": return $"rui/ceaika/name_mp_coliseum_column"
        case "mp_colony02": return $"rui/ceaika/name_mp_colony02"
        case "mp_complex3": return $"rui/ceaika/name_mp_complex3"
        case "mp_crashsite3": return $"rui/ceaika/name_mp_crashsite3"
        case "mp_drydock": return $"rui/ceaika/name_mp_drydock"
        case "mp_eden": return $"rui/ceaika/name_mp_eden"
        case "mp_forwardbase_kodai": return $"rui/ceaika/name_mp_forwardbase_kodai"
        case "mp_glitch": return $"rui/ceaika/name_mp_glitch"
        case "mp_grave": return $"rui/ceaika/name_mp_grave"
        case "mp_homestead": return $"rui/ceaika/name_mp_homestead"
        case "mp_lf_deck": return $"rui/ceaika/name_mp_lf_deck"
        case "mp_lf_meadow": return $"rui/ceaika/name_mp_lf_meadow"
        case "mp_lf_stacks": return $"rui/ceaika/name_mp_lf_stacks"
        case "mp_lf_township": return $"rui/ceaika/name_mp_lf_township"
        case "mp_lf_traffic": return $"rui/ceaika/name_mp_lf_traffic"
        case "mp_lf_uma": return $"rui/ceaika/name_mp_lf_uma"
        case "mp_relic02": return $"rui/ceaika/name_mp_relic02"
        case "mp_rise": return $"rui/ceaika/name_mp_rise"
        case "mp_thaw": return $"rui/ceaika/name_mp_thaw"
        case "mp_wargames": return $"rui/ceaika/name_mp_wargames"
        case "jugg": return $"rui/ceaika/name_jugg"
        case "hotpotato": return $"rui/ceaika/name_hotpotato"
        case "prophunt": return $"rui/ceaika/name_prophunt"
        case "bodyswap": return $"rui/ceaika/name_bodyswap"
        case "ffa": return $"rui/ceaika/name_ffa"
        case "hidden": return $"rui/ceaika/name_hidden"
        case "chamber": return $"rui/ceaika/name_chamber"
        case "gg": return $"rui/ceaika/name_gg"
        case "inf": return $"rui/ceaika/name_inf"
        case "partylobby": return $"rui/ceaika/name_partylobby"
    }
    return $""
}

float function PartyName_Aspect( string key )
{
    switch ( key )
    {
        case "mp_angel_city": return 4.8403
        case "mp_black_water_canal": return 9.1176
        case "mp_coliseum": return 5.8824
        case "mp_coliseum_column": return 3.4034
        case "mp_colony02": return 3.2857
        case "mp_complex3": return 3.9664
        case "mp_crashsite3": return 4.8319
        case "mp_drydock": return 3.9328
        case "mp_eden": return 2.0420
        case "mp_forwardbase_kodai": return 9.1681
        case "mp_glitch": return 2.7815
        case "mp_grave": return 4.9664
        case "mp_homestead": return 5.0252
        case "mp_lf_deck": return 2.1008
        case "mp_lf_meadow": return 3.8739
        case "mp_lf_stacks": return 3.3025
        case "mp_lf_township": return 4.4202
        case "mp_lf_traffic": return 3.3529
        case "mp_lf_uma": return 1.9748
        case "mp_relic02": return 2.2269
        case "mp_rise": return 1.8151
        case "mp_thaw": return 4.8067
        case "mp_wargames": return 5.3193
        case "jugg": return 4.3022
        case "hotpotato": return 3.9496
        case "prophunt": return 3.6763
        case "bodyswap": return 4.0647
        case "ffa": return 4.3094
        case "hidden": return 3.9137
        case "chamber": return 7.1655
        case "gg": return 3.5108
        case "inf": return 3.2806
        case "partylobby": return 4.5396
    }
    return 1.0
}
