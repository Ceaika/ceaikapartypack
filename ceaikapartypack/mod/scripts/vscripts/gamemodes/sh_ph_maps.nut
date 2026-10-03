global function PH_MapModels
global function PH_MapNames
global function PH_MapClasses
global function PH_MapHealth
global function PH_MapSizes
global function PH_SupportedMap
global function PH_MapParts
global function PH_PartTop
global function PH_PartOrigin
global function PH_PartAngles

global struct PHPart
{
    asset owner
    asset model
    vector offset
    vector angles
    float scale
    float top
}
struct
{
    string map = ""
    array<PHPart> list
} phParts

array<asset> function PH_MapModels()
{
    if(GetMapName()=="mp_complex3") return [$"models/furniture/kitchen_set04_chair01.mdl",
        $"models/haven/couch_modular_leather_crnr.mdl",
        $"models/haven/couch_modular_leather_ctr.mdl",
        $"models/levels_terrain/mp_complex/pasted__imc_int_trashbin_02.mdl",
        $"models/containers/pelican_case_large.mdl",
        $"models/containers/pelican_case_large_drabGreen.mdl",
        $"models/domestic/vase_floor_tall_red.mdl",
        $"models/timeshift/timeshift_modern_planter.mdl",
        $"models/furniture/office_chair_leather.mdl",
        $"models/furniture/furniture_patio_table.mdl",
        $"models/timeshift/timeshift_bench_01.mdl",
        $"models/furniture/couch_angular_black_R.mdl",
        $"models/containers/box_small_plastic.mdl",
        $"models/containers/box_small_cardboard.mdl",
        $"models/containers/box_metal.mdl",
        $"models/domestic/glass_coffee_table.mdl",
        $"models/IMC_base/control_desk_IMC_02.mdl",
        $"models/furniture/modular_wall_bench.mdl",
        $"models/containers/gas_tank.mdl",
        $"models/domestic/planters_pots_03.mdl",
        $"models/containers/container_medium_tanks_blue.mdl",
        $"models/timeshift/auditorium_planter_01_d.mdl",
        $"models/furniture/office_chair_modern_01.mdl",
        $"models/containers/box_large_plastic.mdl",
        $"models/furniture/curved_bench_plastic_planter.mdl",
        $"models/furniture/office_chair_modern_plastic.mdl",
        $"models/containers/box_shrinkwrapped.mdl",
        $"models/furniture/office_desk_plastic_modern_04.mdl",
        $"models/furniture/office_desk_plastic_modern_03.mdl",
        $"models/containers/crate.mdl",
        $"models/garbage/garbage_bag_plastic_a.mdl",
        $"models/colony/dirty_bowl_pile_02.mdl",
        $"models/containers/box_mini_cardboard.mdl",
        $"models/furniture/shelves_industrial_01.mdl",
        $"models/beacon/crane_room_monitor_console_static.mdl",
        $"models/domestic/ashcan_standing.mdl",
        $"models/furniture/couch_leather_white_lg.mdl",
        $"models/industrial/pallet_wood.mdl",
        $"models/domestic/trash_garbage_can_exterior_01.mdl",
        $"models/furniture/couch_modular_endTbl1.mdl",
        $"models/IMC_base/control_desk_IMC_01.mdl",
        $"models/furniture/modular_wall_bench_angle.mdl",
        $"models/benches/bench_single_modern.mdl",
        $"models/industrial/tool_chest_top.mdl",
        $"models/domestic/fire_extinguisher_case.mdl",
        $"models/mendoko/mendoko_monitor_01.mdl",
        $"models/mendoko/mendoko_monitor_03.mdl",
        $"models/furniture/computer_monitor_01.mdl"]
    if(GetMapName()=="mp_angel_city") return [$"models/angel_city/box_small_01.mdl",
        $"models/angel_city/box_small_02.mdl",
        $"models/angel_city/fire_hydrant_01.mdl",
        $"models/angel_city/jersey_barrier_large_02.mdl",
        $"models/angel_city/recyclebin_large_01.mdl",
        $"models/angel_city/toy_dispenser_01.mdl",
        $"models/angel_city/vending_machine.mdl",
        $"models/colony/water_heater_white.mdl",
        $"models/containers/barrel.mdl",
        $"models/containers/crate_blue_plastic.mdl",
        $"models/domestic/book_shelf_hallow.mdl",
        $"models/domestic/grain_sack_large_01.mdl",
        $"models/domestic/market_counter_flat.mdl",
        $"models/domestic/rug_rolled_blue.mdl",
        $"models/domestic/trash_can_blue_closed.mdl",
        $"models/domestic/trash_can_green_closed.mdl",
        $"models/domestic/trash_garbage_can_exterior_01.mdl",
        $"models/furniture/couch_leather_white_lg.mdl",
        $"models/furniture/couch_suede_brown_01.mdl",
        $"models/furniture/counter_shop_01.mdl",
        $"models/furniture/furniture_patio_chair.mdl",
        $"models/furniture/kitchen_set01_counter_cabinets01.mdl",
        $"models/furniture/office_desk_shelved.mdl",
        $"models/furniture/shelves_industrial_01.mdl",
        $"models/garbage/garbage_bag_plastic_a.mdl",
        $"models/garbage/trash_bin_single.mdl",
        $"models/garbage/trash_bin_single_blue.mdl",
        $"models/industrial/air_unit_badlands_02_tall.mdl",
        $"models/industrial/air_unit_badlands_02_short.mdl",
        $"models/industrial/cafe_coffe_machine.mdl",
        $"models/industrial/grain_sacks_stacked.mdl",
        $"models/industrial/indoor_console_server.mdl",
        $"models/industrial/keg_small.mdl",
        $"models/industrial/store_fridge_64.mdl",
        $"models/industrial/traffic_cone_01.mdl",
        $"models/industrial/work_cart_plastic.mdl",
        $"models/market/market_table_01.mdl",
        $"models/utilities/power_gen1.mdl",
        $"models/vehicle/vehicle_w3_hatchback/vehicle_w3_hatch_destruction_red.mdl",
        $"models/imc_base/imc_fan_large_case_01.mdl"]
    if(GetMapName()=="mp_colony02") return [$"models/domestic/trash_garbage_can_exterior_01.mdl",
        $"models/domestic/trash_can_blue_closed.mdl",
        $"models/domestic/trash_can_green_closed.mdl",
        $"models/domestic/trash_can_yellow_closed.mdl",
        $"models/containers/barrel.mdl",
        $"models/containers/crate.mdl",
        $"models/containers/crate_blue_plastic.mdl",
        $"models/containers/crate_orange_plastic.mdl",
        $"models/containers/box_med_cardboard_01.mdl",
        $"models/containers/box_med_cardboard_02.mdl",
        $"models/containers/box_med_cardboard_03.mdl",
        $"models/containers/gas_tank.mdl",
        $"models/furniture/dining_chair.mdl",
        $"models/furniture/couch_suede_brown_01.mdl",
        $"models/furniture/kitchen_set02_old_fridge01.mdl",
        $"models/furniture/kitchen_set02_black_old_stove.mdl",
        $"models/furniture/shelves_industrial_01.mdl",
        $"models/domestic/market_counter_flat.mdl",
        $"models/domestic/grain_sack_large_01.mdl",
        $"models/domestic/grain_sack_medium_01.mdl",
        $"models/industrial/grain_sacks_stacked.mdl",
        $"models/angel_city/vending_machine.mdl",
        $"models/domestic/ashcan_standing.mdl",
        $"models/vehicle/vehicle_w3_hatchback/vehicle_w3_hatch_destruction.mdl",
        $"models/IMC_base/cargo_container_imc_01_blue.mdl",
        $"models/IMC_base/cargo_container_imc_01_white.mdl",
        $"models/IMC_base/cargo_container_imc_01_white_open.mdl",
        $"models/industrial/keg_large.mdl",
        $"models/furniture/kitchen_set03_chair01.mdl",
        $"models/furniture/kitchen_set02_black_old_counter1_1.mdl",
        $"models/furniture/kitchen_set02_black_old_counter2_2.mdl",
        $"models/furniture/kitchen_set02_black_old_counter1_2.mdl",
        $"models/containers/box_small_cardboard.mdl",
        $"models/domestic/grain_sack_small_02.mdl",
        $"models/domestic/grain_sack_small_01.mdl",
        $"models/angel_city/toy_dispenser_01.mdl",
        $"models/industrial/store_fridge_64.mdl",
        $"models/industrial/keg_small.mdl",
        $"models/domestic/trash_can_yellow_open.mdl",
        $"models/furniture/kitchen_set02_black_old_sink01.mdl",
        $"models/colony/water_heater_white.mdl",
        $"models/colony/water_heater_red.mdl",
        $"models/industrial/work_cart_plastic.mdl",
        $"models/industrial/cafe_coffe_machine.mdl",
        $"models/industrial/electrical_box_green.mdl",
        $"models/angel_city/sign_cleaning_wetfloor_01.mdl",
        $"models/industrial/tripod_cone_v1_medium_on.mdl",
        $"models/industrial/tripod_cone_v1_low_on.mdl",
        $"models/industrial/lab_push_cart.mdl",
        $"models/industrial/welding_push_unit.mdl",
        $"models/industrial/tool_chest_double.mdl",
        $"models/industrial/purifier_water.mdl",
        $"models/furniture/dining_table1.mdl",
        $"models/domestic/glass_coffee_table.mdl",
        $"models/industrial/roof_ac_unit_med.mdl",
        $"models/garbage/garbage_bag_plastic_a.mdl"]
    return [$"models/domestic/trash_garbage_can_exterior_01_can_only.mdl",
        $"models/furniture/chair_leather.mdl",
        $"models/domestic/toilet_regular_open.mdl",
        $"models/containers/pelican_case_large.mdl",
        $"models/containers/pelican_case_large_drabGreen.mdl",
        $"models/domestic/bookshelf.mdl",
        $"models/containers/news_stand.mdl",
        $"models/furniture/sofa_leather.mdl",
        $"models/furniture/kitchen_set03_cabinet_tall.mdl",
        $"models/furniture/kitchen_set02_counter2.mdl",
        $"models/containers/news_stand_with_graffiti.mdl",
        $"models/barriers/sandbags_single_01.mdl",
        $"models/barriers/sandbags_bent_01.mdl",
        $"models/barriers/sandbags_curved_01.mdl",
        $"models/barriers/sandbags_large_01.mdl",
        $"models/vehicle/vehicle_truck_modular/vehicle_truck_modular_closed_bed_runoff.mdl",
        $"models/vehicle/vehicle_w3_hatchback/vehicle_w3_hatchback_static.mdl",
        $"models/vehicle/vehicle_w3_hatchback/vehicle_w3_hatch_destruction.mdl",
        $"models/vehicle/vehicle_w3_hatchback/vehicle_w3_hatch_destruction_bnw.mdl",
        $"models/IMC_base/cargo_container_imc_01_blue.mdl",
        $"models/IMC_base/cargo_container_imc_01_green.mdl",
        $"models/IMC_base/cargo_container_imc_01_white.mdl",
        $"models/IMC_base/cargo_container_imc_01_blue_open.mdl",
        $"models/IMC_base/cargo_container_imc_01_white_open.mdl",
        $"models/domestic/ac_door_unit.mdl",
        $"models/IMC_base/imc_fan_large_case_01.mdl",
        $"models/kodai_live_fire/live_fire_dummy_02.mdl",
        $"models/kodai_live_fire/live_fire_dummy_03.mdl",
        $"models/kodai_live_fire/live_fire_dummy_05.mdl",
        $"models/beacon/construction_light_large_01_blue_on.mdl",
        $"models/Weapons/ammoboxes/ammo_backpacks.mdl",
        $"models/industrial/light_pole_one_transformer.mdl",
        $"models/beacon/beacon_railing_sml_01.mdl",
        $"models/beacon/beacon_railing_med_01.mdl",
        $"models/s2s/s2s_railing_01_128.mdl",
        $"models/signs/signage_plates_metal/sign_plate_c.mdl",
        $"models/mendoko/mendoko_door_01.mdl",
        $"models/Robots/stalker/stalker_dead_08.mdl",
        $"models/Robots/stalker/stalker_dead_03.mdl",
        $"models/angel_city/keypad_01.mdl",
        $"models/beacon/charge_doorconsole_01.mdl",
        $"models/mp_livefire/township_dlc_sign_01.mdl"]
}
array<string> function PH_MapNames()
{
    if(GetMapName()=="mp_complex3") return ["Kitchen chair", "Leather corner seat", "Leather couch", "Office bin", "Equipment case", "Green equipment case", "Tall red vase", "Modern planter", "Leather office chair", "Patio table", "Long bench", "Black couch", "Plastic box", "Cardboard box", "Metal box", "Glass coffee table", "Control desk", "Wall bench", "Gas canister", "Flower pots", "Blue tank crate", "Long planter", "Office chair", "Large plastic box", "Planter bench", "Plastic chair", "Wrapped pallet", "Office desk", "Small desk", "Wooden crate", "Garbage bag", "Bowl pile", "Tiny box", "Industrial shelves", "Monitor console", "Standing ashtray", "White leather couch", "Wooden pallet", "Street rubbish bin", "Side table", "Control console", "Angled wall bench", "Modern bench", "Tool chest", "Fire extinguisher case", "Monitor bank", "Desk monitor", "Computer monitor"]
    if(GetMapName()=="mp_angel_city") return ["Small cardboard box", "Flat cardboard box", "Fire hydrant", "Concrete barrier", "Recycling bin", "Toy dispenser", "Vending machine", "Water heater", "Barrel", "Blue crate", "Bookshelf", "Grain sack", "Market counter", "Rolled rug", "Blue bin", "Green bin", "Street rubbish bin", "White leather couch", "Brown sofa", "Shop counter", "Patio chair", "Kitchen cabinet", "Office desk", "Industrial shelves", "Garbage bag", "Dumpster", "Blue dumpster", "Tall AC unit", "Short AC unit", "Coffee machine", "Stacked grain sacks", "Server rack", "Keg", "Store fridge", "Traffic cone", "Work cart", "Market table", "Power generator", "Red hatchback", "Large fan case"]
    if(GetMapName()=="mp_colony02") return ["Street rubbish bin", "Blue bin", "Green bin", "Yellow bin", "Barrel", "Wooden crate", "Blue crate", "Orange crate", "Cardboard box A", "Cardboard box B", "Cardboard box C", "Gas tank", "Dining chair", "Brown sofa", "Old refrigerator", "Stove", "Industrial shelves", "Market counter", "Large grain sack", "Grain sack", "Stacked grain sacks", "Vending machine", "Standing ashcan", "Damaged hatchback", "Blue cargo container", "White cargo container", "Open white container", "Large keg", "Kitchen chair", "Kitchen counter", "Wide kitchen counter", "Corner kitchen counter", "Small cardboard box", "Small grain sack", "Small grain sack B", "Toy dispenser", "Store fridge", "Small keg", "Open yellow bin", "Kitchen sink", "White water heater", "Red water heater", "Plastic work cart", "Coffee machine", "Green electrical box", "Wet floor sign", "Work light", "Low work light", "Lab cart", "Welding cart", "Double tool chest", "Water purifier", "Dining table", "Glass coffee table", "Rooftop AC unit", "Garbage bag"]
    return ["Rubbish bin", "Leather chair", "Toilet", "Equipment case", "Green equipment case", "Bookshelf", "Newsstand", "Leather sofa", "Tall kitchen cabinet", "Kitchen counter", "Graffiti newsstand", "Single sandbags", "Bent sandbags", "Curved sandbags", "Large sandbags", "Modular truck", "Hatchback", "Damaged hatchback", "Black-and-white hatchback", "Blue cargo container", "Green cargo container", "White cargo container", "Open blue container", "Open white container", "Air-conditioning unit", "Industrial fan", "Training dummy A", "Training dummy B", "Training dummy C", "Construction light", "Ammo backpacks", "Transformer pole", "Small railing", "Medium railing", "Ship railing", "Metal sign plate", "Industrial door", "Broken Stalker A", "Broken Stalker B", "Wall keypad", "Charge door console", "Township sign"]
}
array<int> function PH_MapClasses()
{
    if(GetMapName()=="mp_complex3") return [0, 2, 2, 1, 1, 1, 0, 1, 1, 1, 0, 2, 0, 0, 0, 0, 2, 2, 0, 0, 2, 0, 1, 1, 0, 0, 2, 1, 0, 0, 0, 0, 0, 1, 1, 0, 2, 0, 1, 0, 2, 2, 1, 0, 0, 1, 0, 0]
    if(GetMapName()=="mp_angel_city") return [2, 0, 1, 2, 1, 0, 1, 2, 1, 0, 0, 1, 2, 0, 0, 0, 1, 2, 2, 2, 1, 2, 2, 1, 0, 2, 2, 2, 1, 0, 2, 1, 1, 1, 0, 0, 2, 2, 2, 2]
    if(GetMapName()=="mp_colony02") return [1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 2, 2, 2, 1, 2, 1, 0, 2, 1, 0, 2, 2, 2, 2, 1, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 0, 2, 2, 2, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 1, 0, 2, 0]
    return [1, 2, 1, 2, 2, 0, 0, 2, 2, 2, 0, 0, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 2, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1]
}
array<int> function PH_MapHealth()
{
    if(GetMapName()=="mp_complex3") return [75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 100, 100, 75, 75, 75, 75, 125, 75, 75, 75, 100, 75, 75, 75, 75, 75, 175, 75, 75, 75, 75, 75, 75, 100, 75, 75, 100, 75, 75, 75, 125, 75, 100, 75, 75, 100, 75, 75]
    if(GetMapName()=="mp_angel_city") return [75, 75, 75, 100, 100, 75, 100, 75, 75, 75, 100, 75, 100, 75, 75, 75, 75, 100, 150, 125, 75, 75, 100, 100, 75, 100, 100, 100, 75, 75, 125, 75, 75, 100, 75, 75, 150, 200, 175, 150]
    if(GetMapName()=="mp_colony02") return [75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 150, 100, 75, 100, 100, 75, 75, 125, 100, 75, 200, 225, 225, 225, 75, 75, 75, 75, 75, 75, 75, 75, 75, 100, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 100, 75]
    return [75, 100, 75, 100, 100, 75, 75, 125, 100, 75, 75, 75, 75, 150, 100, 300, 175, 200, 200, 225, 225, 225, 225, 225, 75, 175, 75, 75, 75, 100, 100, 300, 75, 75, 75, 75, 125, 100, 100, 75, 75, 275]
}
array<vector> function PH_MapSizes()
{
    if(GetMapName()=="mp_complex3") return [<17,17,40>, <35,35,39>, <35,35,42>, <18,18,41>, <41,41,33>, <41,41,33>, <13,13,113>, <20,20,67>, <24,24,50>, <39,39,32>, <69,69,25>, <81,81,35>, <20,20,18>, <17,17,17>, <18,18,15>, <48,48,21>, <49,49,56>, <57,57,41>, <9,9,18>, <13,13,98>, <48,48,43>, <111,111,39>, <23,23,50>, <31,31,30>, <30,30,95>, <19,19,45>, <67,67,80>, <47,47,35>, <33,33,38>, <23,23,20>, <18,18,26>, <11,11,13>, <9,9,9>, <39,39,75>, <37,37,53>, <8,8,35>, <56,56,36>, <49,49,10>, <17,17,39>, <35,35,17>, <49,49,56>, <56,56,41>, <74,74,43>, <22,22,22>, <14,14,39>, <51,51,32>, <25,25,21>, <14,14,24>]
    if(GetMapName()=="mp_angel_city") return [<24,24,33>, <38,38,17>, <25,25,43>, <68,68,39>, <32,32,77>, <22,22,55>, <29,29,81>, <27,27,74>, <23,23,48>, <21,21,14>, <33,33,118>, <19,19,28>, <63,63,40>, <64,64,14>, <21,21,41>, <21,21,41>, <17,17,39>, <56,56,36>, <74,74,54>, <73,73,37>, <22,22,36>, <23,23,37>, <54,54,45>, <39,39,75>, <18,18,26>, <30,30,63>, <30,30,63>, <35,35,74>, <28,28,29>, <34,34,82>, <50,50,59>, <24,24,81>, <17,17,33>, <39,39,97>, <12,12,28>, <25,25,35>, <70,70,62>, <75,75,104>, <97,97,61>, <72,72,129>]
    if(GetMapName()=="mp_colony02") return [<17,17,39>, <20,20,42>, <20,20,42>, <20,20,42>, <23,23,49>, <23,23,20>, <21,21,15>, <10,10,16>, <19,19,26>, <19,19,33>, <19,19,33>, <9,9,18>, <15,15,37>, <73,73,54>, <27,27,78>, <24,24,42>, <39,39,75>, <53,53,40>, <18,18,28>, <18,18,25>, <50,50,59>, <29,29,81>, <8,8,35>, <97,97,63>, <83,83,99>, <83,83,99>, <83,83,99>, <21,21,39>, <14,14,29>, <24,24,41>, <30,30,41>, <30,30,41>, <17,17,17>, <18,18,21>, <18,18,20>, <22,22,55>, <39,39,97>, <17,17,33>, <21,21,41>, <25,25,50>, <27,27,74>, <27,27,74>, <25,25,35>, <34,34,82>, <26,26,66>, <18,18,38>, <22,22,41>, <22,22,31>, <21,21,57>, <21,21,39>, <22,22,49>, <26,26,66>, <30,30,31>, <48,48,21>, <45,45,37>, <18,18,26>]
    return [<17,17,39>, <38,38,48>, <23,23,47>, <41,41,33>, <41,41,33>, <24,24,90>, <15,15,47>, <53,53,48>, <29,29,105>, <24,24,41>, <15,15,47>, <24,24,11>, <20,20,26>, <68,68,42>, <70,70,42>, <198,198,154>, <88,88,62>, <97,97,63>, <97,97,63>, <83,83,99>, <83,83,99>, <83,83,99>, <83,83,100>, <83,83,99>, <31,31,39>, <67,67,129>, <14,14,73>, <14,14,71>, <19,19,72>, <31,31,93>, <53,53,19>, <74,74,388>, <8,8,38>, <16,16,38>, <65,65,53>, <8,8,36>, <49,49,129>, <51,51,29>, <51,51,28>, <7,7,21>, <11,11,39>, <205,205,192>]
}
bool function PH_SupportedMap()
{
    return GetMapName()=="mp_lf_township" || GetMapName()=="mp_colony02" || GetMapName()=="mp_angel_city" || GetMapName()=="mp_complex3"
}

PHPart function PH_Part(asset owner,asset model,vector offset,vector angles,float scale,float top)
{
    PHPart part
    part.owner=owner
    part.model=model
    part.offset=offset
    part.angles=angles
    part.scale=scale
    part.top=top
    return part
}

array<PHPart> function PH_MapParts()
{
    if(phParts.map==GetMapName()) return phParts.list
    phParts.map=GetMapName()
    phParts.list.clear()
    if(GetMapName()=="mp_complex3")
    {
        phParts.list.append(PH_Part($"models/domestic/vase_floor_tall_red.mdl",$"models/foliage/plant_bamboo_manicured01.mdl",< 0.3,-1,37.8 >,< 4.9,0,0 >,1.0,112.4))
        phParts.list.append(PH_Part($"models/timeshift/timeshift_modern_planter.mdl",$"models/foliage/plant_flower_pink_bush.mdl",< -1.29,0.86,44 >,< 0,-114.3,0 >,1.0,66.4))
        phParts.list.append(PH_Part($"models/domestic/planters_pots_03.mdl",$"models/foliage/plant_cypress_small_01.mdl",< -1.5,-1,17.5 >,< 0,0,0 >,1.0,97.9))
        phParts.list.append(PH_Part($"models/furniture/curved_bench_plastic_planter.mdl",$"models/foliage/tree_human_height_med02.mdl",< 0,0,12 >,< 0.2,90,0 >,1.0,94.9))
        phParts.list.append(PH_Part($"models/timeshift/auditorium_planter_01_d.mdl",$"models/foliage/plant_flower_pink_bush.mdl",< -15.7,-64.1,16 >,< -1.7,134.3,-2.3 >,1.0,38.4))
        phParts.list.append(PH_Part($"models/timeshift/auditorium_planter_01_d.mdl",$"models/foliage/plant_flower_pink_bush.mdl",< -7.8,-40,16 >,< 0,90,0 >,1.0,38.4))
        phParts.list.append(PH_Part($"models/timeshift/auditorium_planter_01_d.mdl",$"models/foliage/plant_flower_pink_bush.mdl",< -15.9,-16.1,16 >,< -1.7,134.3,-2.3 >,1.0,38.4))
    }
    if(GetMapName()=="mp_angel_city")
    {
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,-1,74 >,< 0,0,0 >,1.0,87.2))
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,0,54 >,< 0,0,0 >,1.0,67.2))
    }
    if(GetMapName()=="mp_colony02")
    {
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,0,54 >,< 0,0,0 >,1.0,67.2))
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,-1,74 >,< 0,0,0 >,1.0,87.2))
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,8,33 >,< 0,0,0 >,0.75,42.9))
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,-13,19 >,< 0,0,0 >,0.5,25.6))
        phParts.list.append(PH_Part($"models/industrial/store_fridge_64.mdl",$"models/domestic/milk_cluster_01.mdl",< -5,11,19 >,< 0,0,0 >,0.5,25.6))
        phParts.list.append(PH_Part($"models/industrial/tool_chest_double.mdl",$"models/industrial/tool_chest_top.mdl",< 0,0,48.4 >,< 0,0,0 >,1.0,69.4))
        phParts.list.append(PH_Part($"models/industrial/tool_chest_double.mdl",$"models/industrial/tool_chest_top.mdl",< 0,0,68.2 >,< 0,0,0 >,1.0,89.2))
    }
    return phParts.list
}

float function PH_PartTop(asset owner)
{
    float top=0.0
    array<PHPart> parts=PH_MapParts()
    for(int i=0;i<parts.len();i++) if(parts[i].owner==owner) top=max(top,parts[i].top)
    return top
}
vector function PH_PartOrigin(vector origin,vector angles,vector offset)
{
    return origin+AnglesToForward(angles)*offset.x-AnglesToRight(angles)*offset.y+AnglesToUp(angles)*offset.z
}
vector function PH_PartAngles(vector angles,vector partAngles)
{
    return <partAngles.x,angles.y+partAngles.y,partAngles.z>
}
