(ns core
  (:require
   [cljs.core.async :refer [go]]
   [cljs.core.async.interop :refer-macros [<p!]])
  (:require ["mqtt" :as mqtt])
  (:require [logseq]))

(defn send_tasks [mqtt]
  (go
    (let [block (js->clj (<p! (logseq/current-block)))]
      (try
        (.publish mqtt "tasks" (get block "content"))
        (catch js/Error err (js/console.log (ex-cause err))))
      (println block))))

(defn main []
  (let [mqtt (mqtt/connect "ws://192.168.1.153:8083")]
    ((.on mqtt "connect" (fn [_] (logseq/send-msg "Task Tiler: MQTT Connected")))
     (.on mqtt "packetsend" (fn [pack] (when (= (get (js->clj pack) "cmd") "publish") (logseq/send-msg "Sending tasks"))))
     (js/logseq.Editor.registerSlashCommand "tiler" (fn [] (send_tasks mqtt))))))


(defn init []
  (-> (js/logseq.ready main)
      (.catch js/console.error)))

(comment
  (logseq/send-msg "hi"))