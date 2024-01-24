import mqtt from "mqtt"

export function connectImpl(addr, opt) {
    return () => {
        return mqtt.connect(addr, opt)
    }
}

export function publishImpl(client, topic, msg) {
    return () => {
        client.publish(topic, msg, {retain: true})
    }
}
