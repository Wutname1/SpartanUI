-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

-- ----------------------------------------------------------------------------
-- Statistics: Populated and maintained in UpdateStatistics()
-- ----------------------------------------------------------------------------
local People = {
    BattleNet = {
        Online = 0,
        Total = 0,
    },
    Friends = {
        Online = 0,
        Total = 0,
    },
    GuildMembers = {
        Online = 0,
        Total = 0,
    },
}

private.People = People

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
function private.UpdateStatistics()
    People.BattleNet.Total, People.BattleNet.Online = BNGetNumFriends()
    People.Friends.Total = C_FriendList.GetNumFriends()
    People.Friends.Online = C_FriendList.GetNumOnlineFriends()

    if IsInGuild() then
        local _
        People.GuildMembers.Total, _, People.GuildMembers.Online = GetNumGuildMembers()
    end
end
