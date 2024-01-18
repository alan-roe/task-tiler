(ns logseq
  (:require ["@logseq/libs"]))

(defn send-msg
  ([msg] (js/logseq.App.showMsg msg))
  ([msg level] (js/logseq.App.showMsg msg level)))

(defn current-block []
  (js/logseq.Editor.getCurrentBlock))