import { openDashboard } from "./edge";

export default async function Command() {
  await openDashboard("emservices-grafana-nonprod");
}
