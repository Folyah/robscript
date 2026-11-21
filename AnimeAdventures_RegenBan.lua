-- Folyah: RobScript original completo + unica regra: Regen proibido na Dungeon.
-- Nao modifica Shielding, lojas, farms, posicionamento ou Summer Hunt.
-- Fonte original armazenada no proprio repositorio: Folyah/robscript.
local url = "https://raw.githubusercontent.com/Folyah/robscript/main/AnimeAdventures"
local source = game:HttpGet(url)
assert(type(source) == "string" and #source > 100000, "RobScript completo nao encontrado")

local function replaceExactlyOnce(before, after, label)
    local a, b = source:find(before, 1, true)
    assert(a, "RobScript: trecho nao encontrado: " .. label)
    assert(not source:find(before, b + 1, true), "RobScript: trecho duplicado: " .. label)
    source = source:sub(1, a - 1) .. after .. source:sub(b + 1)
end

replaceExactlyOnce([===[function Dungeon.curseOk(sxb, txb, uxb, vxb, wxb)
]===], [===[function Dungeon.isRegenCurse(id)
    return Dungeon.isCurse(id) and tostring(id):lower():find("regen", 1, true) ~= nil
end

function Dungeon.curseOk(sxb, txb, uxb, vxb, wxb)
    if Dungeon.isRegenCurse(sxb) then
        return false, "Regen is forbidden in Dungeon"
    end
]===], "patch 1")

replaceExactlyOnce([===[        local qyb, ryb, syb = pcall(Dungeon.curseGate, fyb, Uxb)
        if qyb and not ryb then
            fyb.blocked = syb
        end
]===], [===[        local qyb, ryb, syb = pcall(Dungeon.curseGate, fyb, Uxb)
        if Dungeon.isRegenCurse(Dungeon.roomCurse(fyb.r)) then
            fyb.blocked = "Regen is forbidden in Dungeon"
        elseif qyb and not ryb then
            fyb.blocked = syb
        end
]===], "patch 2")

replaceExactlyOnce([===[        if not dyb or fyb.score > dyb.score then
            dyb = fyb
        end
]===], [===[        if not Dungeon.isRegenCurse(Dungeon.roomCurse(fyb.r))
            and (not dyb or fyb.score > dyb.score) then
            dyb = fyb
        end
]===], "patch 3")

replaceExactlyOnce([===[    if not iCb then
        Dungeon.logState(cCb, "no rooms on offer")
]===], [===[    if not iCb then
        if # Dungeon.rooms(cCb) > 0 then
            Dungeon.note("all available rooms contain Regen; returning to lobby automatically")
            App.saveNow()
            App.request("lobby", "teleport_back_to_lobby")
            return false
        end
        Dungeon.logState(cCb, "no rooms on offer")
]===], "patch 4")

-- Interface preservada no fork de Folyah/Robly_Airflow.
-- Faça o fork antes de executar este loader, para que a biblioteca seja encontrada.
replaceExactlyOnce([===[Core.AIRFLOW_URL = "https://raw.githubusercontent.com/bobloscript/Robly_Airflow/main/Source.luau"]===], [===[Core.AIRFLOW_URL = "https://raw.githubusercontent.com/Folyah/Robly_Airflow/main/Source.luau"]===], "interface Robly Airflow propria")

-- Se o codigo original mudar, a validacao interrompe a execucao em vez de
-- carregar silenciosamente um script sem o banimento de Regen.
local run, err = loadstring(source, "=Folyah_AnimeAdventures_RegenBan")
assert(run, err)
return run()
