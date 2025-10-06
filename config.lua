Config = {}

Config.Debug = false

Config.EnableLogs = {
    Shooting = true,
    Damage = true, 
    Aim = true,
    Resource = true,
    Explosion = true,
    Connect = true,
    Chat = true,
    PlayerLeave = true,
    Kill = true,
    NewPlayer = true,
}

Config.WebhookURL = {
    Join    = 'YOUR_WEBHOOK_URL_HERE',
    Leave   = 'YOUR_WEBHOOK_URL_HERE',
    Chat    = 'YOUR_WEBHOOK_URL_HERE',
    Aim     = 'YOUR_WEBHOOK_URL_HERE',
    Kill    = 'YOUR_WEBHOOK_URL_HERE',
    Resource = 'YOUR_WEBHOOK_URL_HERE',
    Explosion = 'YOUR_WEBHOOK_URL_HERE',
    Shooting = 'YOUR_WEBHOOK_URL_HERE',
    Damage = 'YOUR_WEBHOOK_URL_HERE',
    NewPlayer = 'YOUR_WEBHOOK_URL_HERE',
}

Config.EmbedColors = {
    Join  = 3066993,    -- Green
    Leave = 15158332,   -- Red
    Chat  = 3447003,    -- Blue
    Aim   = 16776960,   -- Yellow
    Kill  = 15158332,   -- Red
    Resource = 4437377,  -- Grey/Purple
    Explosion = 16753920, -- Orange
    Shooting = 15844367, -- Gold
    Damage = 13382717,   -- Pink 
    NewPlayer  = 3066993, -- Green 
}

Config.WeaponsNotLogged = {
    'WEAPON_UNARMED',
    'WEAPON_STUNGUN',

}
