import Dzen
import Data.Char (isSpace)
import XMonad
import qualified XMonad.StackSet as W -- to shift and float windows
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Util.Run
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Actions.TagWindows
import XMonad.Actions.CycleWS
import XMonad.Actions.CycleWindows
import XMonad.Actions.CycleRecentWS
import XMonad.Actions.UpdatePointer
import qualified Data.Map as M


-- Workspace dzen bar
myStatusBar = DzenConf {
      x_position = Just 400
    , y_position = Just 0
    , width      = Just 1060
    , height     = Just 24
    , alignment  = Just LeftAlign
    , font       = Just "Bitstream Sans Vera:pixelsize=11"
    , fg_color   = Just "#ffffff"
    , bg_color   = Just "#000000"
    , exec       = []
    , addargs    = []
}
-- Workspace dzen bar
myClockDzen = DzenConf {
      x_position = Just 1460
    , y_position = Just 0
    , width      = Just 220
    , height     = Just 24
    , alignment  = Just LeftAlign
    , font       = Just "Bitstream Sans Vera:pixelsize=11"
    , fg_color   = Just "#ffffff"
    , bg_color   = Just "#000000"
    , exec       = []
    , addargs    = []
}

-- Log hook that prints out everything to a dzen handler
myLogHook h = dynamicLogWithPP $ myPrettyPrinter h 

-- Pretty printer for dzen workspace bar
myPrettyPrinter h = dzenPP {
      ppOutput          = hPutStrLn h
    , ppCurrent         = dzenColor "#000000" "#e5e5e5" . pad
    , ppHidden          = dzenColor "#e5e5e5" "#000000" . pad . clickable myWorkspaces . trimSpace . noScratchPad
    , ppHiddenNoWindows = dzenColor "#444444" "#000000" . pad . clickable myWorkspaces . trimSpace . noScratchPad
    , ppUrgent          = dzenColor "#ff0000" "#000000" . pad . clickable myWorkspaces . trimSpace . dzenStrip
    , ppWsSep           = " "
    , ppSep             = " | "
    , ppTitle           = (" " ++) . dzenColor "#ffffff" "#000000" . shorten 50 . dzenEscape
    --, ppLayout          = dzenColor "#964AFF" "#000000" . pad .
    --                      (\x -> case x of
    --                        "Spacing 10 Tall"           -> "Tall"
    --                        "SimplestFloat"             -> "Float"
    --                        "Mirror Spacing 10 Tall"    -> "Mirror"
    --                        _                           -> x
    --                      )
    }
    where
        noScratchPad ws = if ws /= "NSP" then ws else ""

-- Wraps a workspace name with a dzen clickable action that focusses that workspace
clickable workspaces workspace = clickableExp workspaces 1 workspace
clickableExp [] _ ws = ws
clickableExp (ws:other) n l | l == ws = "^ca(1,xdotool key super+F" ++ show (n) ++ ")" ++ ws ++ "^ca()"
                            | otherwise = clickableExp other (n+1) l

-- Trims leading and trailing white space
trimSpace = f . f
    where f = reverse . dropWhile isSpace

main = do
    workspaceBar <- spawnDzen myStatusBar
    spawnToDzen "conky -c ~/.conky/daterc" myClockDzen
    xmonad $ withUrgencyHook NoUrgencyHook $ defaultConfig {
        modMask = mod4Mask -- use the windows button
      , logHook = myLogHook workspaceBar
      , manageHook = manageDocks <+> myManageHook
      , workspaces = myWorkspaces
      , terminal = "urxvt"
      , layoutHook = avoidStruts $ smartBorders (ResizableTall 1 (3/100) (1/2) [] ||| layoutHook defaultConfig)
      , keys = myKeys
    } 
myWorkspaces = ["1:web","2:terms","3:vms","4:tools","5:term2","6:hell","7:hades", "8:neverland", "9:chat"]

myManageHook = ( composeAll
    [ className =? "Vmware" --> doShift "3:vms"
    , className =? "Chromium" --> doShift "1:web"
    --, className =? "Idaq" --> doShift "4:tools"
    , className =? "htop" --> doShift "7:stats"
    ] )

-- Define new key combinations to be added
keysToAdd x =
    [
          ((mod4Mask, xK_z), sendMessage MirrorShrink)
        , ((mod4Mask, xK_a), sendMessage MirrorExpand)
        -- capture window
        , ((controlMask, xK_Print), spawn "sleep 0.2; scrot -s") --capture window
        -- capture full screen
        , ((0, xK_Print), spawn "scrot") -- full screen capture
        , ((mod4Mask, xK_v), focusUpTaggedGlobal "vms")
        -- Shift to prevous workspace
        , (((modMask x .|. controlMask), xK_Left), moveTo Prev (WSIs notSP))
        -- Shift to next window
        , (((modMask x .|. controlMask), xK_Right), moveTo Next (WSIs notSP))
        -- Shift window to previous workspace
        , (((modMask x .|. shiftMask), xK_Left), shiftTo Prev (WSIs notSP))
        -- Shift window to next workspace
        , (((modMask x .|. shiftMask), xK_Right), shiftTo Next (WSIs notSP))
        -- Focus most recent urgent window
        , ((modMask x, xK_u), focusUrgent)
        -- Increment the number of windows in the master area
        , ((modMask x .|. shiftMask, xK_KP_Add), sendMessage (IncMasterN 1))
        -- Deincrement the number of windows in the master area
        , ((modMask x .|. shiftMask, xK_KP_Subtract), sendMessage (IncMasterN (-1)))
        -- Toggle struts
        , ((modMask x, xK_b), sendMessage ToggleStruts)
        -- Move active window to master pane
        , ((mod4Mask, xK_Return), windows W.swapMaster)
        -- Rebind mod + q: custom restart xmonad script
        , ((modMask x, xK_q), spawn "killall conky dzen2 && xmonad --recompile && xmonad --restart")

        , ((mod4Mask, xK_Tab), cycleRecentWS [xK_Super_L] xK_Tab xK_grave
            >> updatePointer (Relative 0.5 0.5))
    ]
    ++
    [
        -- Focus workspace / shift workspace
        ((modMask x .|. m, k), windows $ f i)
        | (i,k) <- zip (myWorkspaces) [xK_F1 .. xK_F9]
        , (f,m) <- [(W.view, 0), (W.shift, shiftMask)]
    ]
      where
        notSP = (return $ ("NSP" /=) . W.tag) :: X (WindowSpace -> Bool)
keysToRemove x = 
    [
        (mod4Mask, xK_Tab)
    ]
-- Delete the key combinations to be removed from the original keys
newKeys x = foldr M.delete (keys defaultConfig x) (keysToRemove x)
-- Merge new key combinations with existing keys
myKeys x = M.union (newKeys x) (M.fromList (keysToAdd x))

