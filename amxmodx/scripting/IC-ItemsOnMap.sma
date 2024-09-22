#include <amxmodx>
#include <reapi>
#include <json>
#include <VipM/ItemsController>

new ConfigsDirectory[] = "IC-ItemsOnMap";

new Array:Items = Invalid_Array;
new Float:DelaySeconds = -1.0;

public plugin_precache() {
    register_plugin("[IC] Items On Map", "1.0.0", "ArKaNeMaN");
    VipM_IC_Init();

    FindAndLoadItemsFromFolder(CfgUtils_MakePath("Maps"));

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "@OnSpawnEquip", true);
}

@OnSpawnEquip(const playerIndex, const bool:addDefault, const bool:equipGame) {
    if (Items == Invalid_Array) {
        return;
    }

    if (DelaySeconds < 0.0) {
        @Task_Give(playerIndex);
    } else {
        set_task(DelaySeconds, "@Task_Give", playerIndex);
    }
}

@Task_Give(const playerIndex) {
    if (!is_user_alive(playerIndex)) {
        return;
    }

    VipM_IC_GiveItems(playerIndex, Items);
}

FindAndLoadItemsFromFolder(const path[]) {
    ArrayDestroy(Items);

    new mapName[32];
    rh_get_mapname(mapName, charsmax(mapName), MNT_TRUE);

    new filePath[PLATFORM_MAX_PATH];
    if (file_exists(fmt("%s/%s.json", path, mapName))) {
        filePath = fmt("%s/%s.json", path, mapName);
    } else if (file_exists(fmt("%s/_other.json", path))) {
        filePath = fmt("%s/_other.json", path);
    }

    if (filePath[0] != EOS) {
        LoadItemsFromFile(filePath);
    }

    if (Items == Invalid_Array || ArraySize(Items) < 1) {
        log_amx("No items loaded.");
    } else {
        log_amx("%d items loaded from '%s'.", ArraySize(Items), filePath);
    }
}

LoadItemsFromFile(const path[]) {
    new JSON:cfgJson = json_parse(path, true, true);
    LoadItemsFromJson(cfgJson);
    json_free(cfgJson);
}

LoadItemsFromJson(const JSON:cfgJson) {
    if (!json_object_has_value(cfgJson, "Items")) {
        return;
    }

    Items = VipM_IC_JsonGetItems(json_object_get_value(cfgJson, "Items"));

    if (json_object_has_value(cfgJson, "Delay", JSONNumber)) {
        DelaySeconds = json_object_get_real(cfgJson, "Delay");
    }
}

// CfgUtils.inc

// Simplified https://github.com/AmxxModularEcosystem/CustomWeaponsAPI/blob/master/amxmodx/scripting/Cwapi/CfgUtils.inc#L32-L43
CfgUtils_MakePath(const path[]) {
    static __amxx_configsdir[PLATFORM_MAX_PATH];
    if (!__amxx_configsdir[0]) {
        get_localinfo("amxx_configsdir", __amxx_configsdir, charsmax(__amxx_configsdir));
    }

    new out[PLATFORM_MAX_PATH];
    formatex(out, charsmax(out), "%s/plugins/%s/%s", __amxx_configsdir, ConfigsDirectory, path);

    return out;
}