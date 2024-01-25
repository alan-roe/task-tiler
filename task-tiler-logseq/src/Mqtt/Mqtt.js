import mqtt from '../../node_modules/mqtt/dist/mqtt.esm.js';

export function connectImpl(addr, opt) {
    return () => {
        return mqtt.connect(addr, opt)
    }
}

export function publishImpl(client, topic, msg, opts) {
    return () => {
        client.publish(topic, msg, opts)
    }
}
