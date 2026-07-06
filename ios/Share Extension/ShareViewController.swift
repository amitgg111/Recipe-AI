//
//  ShareViewController.swift
//  Share Extension
//
//  Receives content shared into Recipe AI from the iOS share sheet and hands it
//  to the host app (via receive_sharing_intent's RSIShareViewController).
//
//  NOTE: if you get "No such module 'receive_sharing_intent'", open the Runner
//  target > Build Phases and drag "Embed Foundation Extensions" ABOVE the
//  "Thin Binary" phase, then clean-build.
//
import receive_sharing_intent

class ShareViewController: RSIShareViewController {

    // Return true to immediately open the host app to process the shared recipe
    // (no intermediate "Post" compose screen). This mirrors the Android flow.
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
