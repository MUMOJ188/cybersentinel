import { useEffect, useRef, useState } from "react";
import { Socket, Channel } from "phoenix";
import { API_BASE_URL } from "../api/client";
import type { Alert } from "../types";

const SOCKET_URL = API_BASE_URL.replace(/\/api$/, "").replace(/^http/, "ws") + "/socket";

/**
 * Joins "alerts:lobby" and appends every `new_alert` push the backend
 * broadcasts (see AlertChannel + Alerts.create_alert's PubSub.broadcast).
 * Returns the live list plus a running counter for the notification badge.
 */
export function useAlertsSocket(token: string | null) {
  const [liveAlerts, setLiveAlerts] = useState<Alert[]>([]);
  const socketRef = useRef<Socket | null>(null);
  const channelRef = useRef<Channel | null>(null);

  useEffect(() => {
    if (!token) return;

    const socket = new Socket(SOCKET_URL, { params: { token } });
    socket.connect();
    socketRef.current = socket;

    const channel = socket.channel("alerts:lobby", {});
    channel
      .join()
      .receive("error", (resp) => console.error("alerts channel join failed", resp));

    channel.on("new_alert", (payload: Alert) => {
      setLiveAlerts((prev) => [payload, ...prev].slice(0, 100));
    });

    channelRef.current = channel;

    return () => {
      channel.leave();
      socket.disconnect();
    };
  }, [token]);

  return { liveAlerts, clearLiveAlerts: () => setLiveAlerts([]) };
}
