URLRewrite = require '../url_rewrite'

describe "URLRewrite", ->
    env = null

    it "should reject urls not in whitelist", ->
        env = {}
        env.get = ()->
            [/example.net/]
        rewriter = new URLRewrite(env)

        expect(rewriter.isSafeUrl('client.example.com')).toBe(false)

    it "should accept urls in the whitelist", ->
        env = {}
        env.get = ()->
            [/^http[s]*:\/\/replay_.*net/]
        rewriter = new URLRewrite(env)

        expect(rewriter.isSafeUrl('https://replay_client.example.net')).toBe(true)
