---
paths: ["scripts/**/remote*.lua"]
---

# Inter-mod Communication

For inter-mod communication, the global `remote` object is provided.

Example:

```lua
-- Mod A
remote.add_interface("mod-A", {
    hello = function ()
        print("mod-A.hello is called")
    end,
    test = function (arg1, arg2)
        print("mod-A.test is called with " .. arg1 .. " and " .. arg2)
    end
})

-- Mod B
remote.call("mod-A", "hello") -- prints "mod-A.hello is called"
remote.call("mod-A", "test", "ABC", 123) -- prints "mod-A.test is called with ABC and 123"
```
