Configuration FirewalldEnabled {
 
    Import-DscResource -ModuleName 'GuestConfiguration' -ModuleVersion '1.19.0.0'
    Node FirewalldEnabled {
        ChefInSpecResource FirewalldEnabled {
            Name = 'FirewalldEnabled'
            AttributesYmlContent = "DefaultFirewalldProfile: public"
        }
    }
}

FirewalldEnabled


