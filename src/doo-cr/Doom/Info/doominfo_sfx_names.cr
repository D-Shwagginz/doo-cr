#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr::DoomInfo
  class_getter sfx_names : Array(DoomString) = [
    DoomString.new("none"),
    DoomString.new("pistol"),
    DoomString.new("shotgn"),
    DoomString.new("sgcock"),
    DoomString.new("dshtgn"),
    DoomString.new("dbopn"),
    DoomString.new("dbcls"),
    DoomString.new("dbload"),
    DoomString.new("plasma"),
    DoomString.new("bfg"),
    DoomString.new("sawup"),
    DoomString.new("sawidl"),
    DoomString.new("sawful"),
    DoomString.new("sawhit"),
    DoomString.new("rlaunc"),
    DoomString.new("rxplod"),
    DoomString.new("firsht"),
    DoomString.new("firxpl"),
    DoomString.new("pstart"),
    DoomString.new("pstop"),
    DoomString.new("doropn"),
    DoomString.new("dorcls"),
    DoomString.new("stnmov"),
    DoomString.new("swtchn"),
    DoomString.new("swtchx"),
    DoomString.new("plpain"),
    DoomString.new("dmpain"),
    DoomString.new("popain"),
    DoomString.new("vipain"),
    DoomString.new("mnpain"),
    DoomString.new("pepain"),
    DoomString.new("slop"),
    DoomString.new("itemup"),
    DoomString.new("wpnup"),
    DoomString.new("oof"),
    DoomString.new("telept"),
    DoomString.new("posit1"),
    DoomString.new("posit2"),
    DoomString.new("posit3"),
    DoomString.new("bgsit1"),
    DoomString.new("bgsit2"),
    DoomString.new("sgtsit"),
    DoomString.new("cacsit"),
    DoomString.new("brssit"),
    DoomString.new("cybsit"),
    DoomString.new("spisit"),
    DoomString.new("bspsit"),
    DoomString.new("kntsit"),
    DoomString.new("vilsit"),
    DoomString.new("mansit"),
    DoomString.new("pesit"),
    DoomString.new("sklatk"),
    DoomString.new("sgtatk"),
    DoomString.new("skepch"),
    DoomString.new("vilatk"),
    DoomString.new("claw"),
    DoomString.new("skeswg"),
    DoomString.new("pldeth"),
    DoomString.new("pdiehi"),
    DoomString.new("podth1"),
    DoomString.new("podth2"),
    DoomString.new("podth3"),
    DoomString.new("bgdth1"),
    DoomString.new("bgdth2"),
    DoomString.new("sgtdth"),
    DoomString.new("cacdth"),
    DoomString.new("skldth"),
    DoomString.new("brsdth"),
    DoomString.new("cybdth"),
    DoomString.new("spidth"),
    DoomString.new("bspdth"),
    DoomString.new("vildth"),
    DoomString.new("kntdth"),
    DoomString.new("pedth"),
    DoomString.new("skedth"),
    DoomString.new("posact"),
    DoomString.new("bgact"),
    DoomString.new("dmact"),
    DoomString.new("bspact"),
    DoomString.new("bspwlk"),
    DoomString.new("vilact"),
    DoomString.new("noway"),
    DoomString.new("barexp"),
    DoomString.new("punch"),
    DoomString.new("hoof"),
    DoomString.new("metal"),
    DoomString.new("chgun"),
    DoomString.new("tink"),
    DoomString.new("bdopn"),
    DoomString.new("bdcls"),
    DoomString.new("itmbk"),
    DoomString.new("flame"),
    DoomString.new("flamst"),
    DoomString.new("getpow"),
    DoomString.new("bospit"),
    DoomString.new("boscub"),
    DoomString.new("bossit"),
    DoomString.new("bospn"),
    DoomString.new("bosdth"),
    DoomString.new("manatk"),
    DoomString.new("mandth"),
    DoomString.new("sssit"),
    DoomString.new("ssdth"),
    DoomString.new("keenpn"),
    DoomString.new("keendt"),
    DoomString.new("skeact"),
    DoomString.new("skesit"),
    DoomString.new("skeatk"),
    DoomString.new("radio"),
  ]
end
