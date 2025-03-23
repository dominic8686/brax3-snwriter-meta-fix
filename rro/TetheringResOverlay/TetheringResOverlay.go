package mtkTetheringResOverlay

import (
    "android/soong/android"
    "android/soong/java"
    "fmt"
)

func init() {
    android.RegisterModuleType("mtk_TetheringResOverlay_defaults", mtkTetheringResOverlayDefaultsFactory)
}

func mtkTetheringResOverlayDefaultsFactory() android.Module {
    module := java.DefaultsFactory()
    android.AddLoadHook(module, mtkTetheringResOverlayDefaults)
    return module
}

func mtkTetheringResOverlayDefaults(ctx android.LoadHookContext) {
    type props struct {
        Resource_dirs []string
    }
    p := &props{}
    vars := ctx.Config().VendorConfig("mtkPlugin")
    var resDir []string

    if vars.String("MTK_AIV_SUPPORT") == "yes" {
        resDir = append(resDir, "tethering_bluetooth_disable/res/")
    }
    fmt.Println("TetheringResOverlay Resource Dirs: ", resDir)
    p.Resource_dirs = resDir
    ctx.AppendProperties(p)
}
