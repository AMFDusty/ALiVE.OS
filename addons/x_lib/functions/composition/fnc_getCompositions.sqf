#include <\x\alive\addons\x_lib\script_component.hpp>
SCRIPT(getCompositions);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_getCompositions

Description:
Returns an array of composition configs

Parameters:
String - Type - Civilian, Military, Guerrilla
Array - Category name(s) - leave [] for any

    Civilian Categories - airports, checkpoints, construction, constructionSupplies, comms, fuel, general, heliports, industrial, marine, mining_oil, power, rail, settlements
    Guerrilla Categories - camps, checkpoints, constructionsupplies, comms, fieldhq, fort, fuel, hq, marine, medical, outposts, power, supports
    Military Categories - airports, camps, checkpoints, constructionsupplies, comms, crashsites, fieldhq, fort, fuel, heliports, hq, marine, medical, outposts, power, supports

Array - Size - ["Large","Medium","Small"] - leave [] for any size
Array - Faction (Optional) - leave [] for any size

Returns:
Array - Of composition configs, empty array if nothing found

Examples:
(begin example)
//
_result = [_compType, _cat, _size, _faction] call ALiVE_fnc_getCompositions;
(end)

See Also:

Author:
ARJay
---------------------------------------------------------------------------- */

private ["_className","_configPaths","_configPath","_result","_item","_comp","_name","_size","_cat","_faction","_compType","_enemyFactions"];

_compType = _this select 0;
_cat = if (typeName (_this select 1) == "ARRAY") then {_this select 1} else {[_this select 1]};
_size = if (typeName (_this select 2) == "ARRAY") then {_this select 2} else {[_this select 2]};
if (count _this > 3) then {
    if (typeName (_this select 3) == "ARRAY") then {_faction = _this select 3} else {_faction = [_this select 3]};
} else {
    _faction = [];
};

_enemyFactions = [];

if (!isNil "ALiVE_mapCompositionType") then {
    _env = ALiVE_mapCompositionType;
};

_result = [];

if (count _cat == 0 || (_cat select 0) == "") then {
    _cat = ["any"];
};

if (count _size == 0 || (_size select 0) == "") then {
    _size = ["any"];
};

if (count _faction == 0 || (_faction select 0) == "") then {
    _faction = ["any"];
};

if (!isNil "_env") then {
    _compType = format["%1_%2",_compType,_env]; // Civilian_Pacific etc
};

_configPaths = [
    missionConfigFile >> "CfgGroups" >> "Empty" >> _compType,
    configFile >> "CfgGroups" >> "Empty" >> _compType
];

// Get enemy factions
if (_faction select 0 != "any") then {
    {
        private ["_enemySide","_friendlySide"];
        _friendlySide = _x call ALiVE_fnc_factionSide;
        _enemySide = [EAST];
        if (_friendlySide == EAST) then {_enemySide = [WEST,RESISTANCE];} else {_enemySide = [EAST];};
        if (_friendlySide == EAST && [RESISTANCE, WEST] call BIS_fnc_sideIsEnemy) then {_enemySide = [WEST];};
        if (_friendlySide == RESISTANCE && [RESISTANCE, WEST] call BIS_fnc_sideIsEnemy) then {_enemySide = [WEST];};
        {
            private ["_enemy"];
            _enemy = _x;
            _enemy = [_enemy] call ALIVE_fnc_sideObjectToNumber;
            _enemy = [_enemy] call ALIVE_fnc_sideNumberToText;
            {
                if !(_x in _enemyFactions) then {
                    _enemyFactions pushback _x;
                };
            } foreach (_enemy call ALiVE_fnc_getSideFactions);
            diag_log format["FRIEND %1",_friendlySide];
            diag_log format["ENEMY %1",_enemy];
        } foreach _enemySide;
    } foreach _faction;
    diag_log _enemyFactions;
};

scopeName "main";

{
    _configPath = _x; // Military_Pacific

    for "_i" from 0 to ((count _configPath) - 1) do
    {

        _item = _configPath select _i; // airports

        if (isClass _item && ("any" in _cat || ({tolower(configName _item) find tolower(_x) != -1} count _cat > 0))) then {

            if ("any" in _size || ({tolower(configName _item) find tolower(_x) != -1} count _size > 0)) then { // airportslarge

                for "_i" from 0 to ((count _item) - 1) do
                {
                    _comp = _item select _i;
                    // diag_log str(_comp);
                    if (isClass _comp) then {

                            if ({(configName _comp) find _x != -1} count _enemyFactions == 0 ||  _faction select 0 == "any" ) then {
                                diag_log (configName _comp);
                                _result pushback _comp;
                            };
                    };
                };
            };
        };
    };
} foreach _configPaths;

if (count _result == 0) then {
    _result = [_compType,_cat,[]] call ALiVE_fnc_getCompositions;
};

["Found %1 compositions for %2", count _result, _this] call ALiVE_fnc_dump;

_result
