ReplayClient = require '../lib/replay_client'

describe "ReplayClient", ->
    it "should parse object post params to strings", ->
        replay_client = new ReplayClient
        parsed_data = replay_client.parse({
            patient: {'first_name': 'john'}
            address: {'line_1': 'Some street'}
        }, '')
        expect(parsed_data).toEqual(
            {
                'patient[first_name]': 'john'
                'address[line_1]': 'Some street'
            }
        )

    it "should parse basic string parameters", ->
        replay_client = new ReplayClient
        parsed_data = replay_client.parse {json: "{'first_name': 'john'}"}, ''
        expect(parsed_data).toEqual(
            {'json': "{'first_name': 'john'}"}
        )
