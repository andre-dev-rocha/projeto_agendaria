// functions/index.js
const functions = require("firebase-functions");
const { WebhookClient } = require("dialogflow-fulfillment");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

exports.agendariaWebhook = functions.https.onRequest((request, response) => {
  const agent = new WebhookClient({ request, response });

  async function agendarServico(agent) {
    const { servico, date, time } = agent.parameters;
    const serviceName = servico;

    const appointmentDate = new Date(date.split("T")[0] + "T" + time.split("T")[1]);

    // TODO: Por enquanto, vamos pegar o primeiro funcionário que oferece o serviço.
    // No futuro, o bot poderia perguntar "Com qual profissional?".
    const serviceSnapshot = await db.collection("services").where("name", "==", serviceName).limit(1).get();

    if (serviceSnapshot.empty) {
      agent.add(`Desculpe, não oferecemos o serviço "${serviceName}".`);
      return;
    }

    const serviceData = serviceSnapshot.docs[0].data();
    const employeeId = serviceData.employeeId;
    const durationMinutes = serviceData.durationMinutes;

    // 1. Verificar a disponibilidade do funcionário (dia e hora)
    const availabilityRef = db.collection("availabilities").doc(employeeId);
    const availabilityDoc = await availabilityRef.get();

    if (!availabilityDoc.exists) {
      agent.add("Desculpe, o profissional não tem horários cadastrados.");
      return;
    }

    const weekdays = ["domingo", "segunda", "terca", "quarta", "quinta", "sexta", "sabado"];
    const dayOfWeek = weekdays[appointmentDate.getDay()];
    const employeeSchedule = availabilityDoc.data();
    const daySchedule = employeeSchedule[dayOfWeek];

    if (!daySchedule || !daySchedule.isAvailable) {
      agent.add(`Desculpe, não há atendimento na ${dayOfWeek}-feira. Por favor, escolha outro dia.`);
      return;
    }

    const startTime = daySchedule.startTime.split(":");
    const endTime = daySchedule.endTime.split(":");
    const startAvailability = new Date(appointmentDate).setHours(startTime[0], startTime[1], 0, 0);
    const endAvailability = new Date(appointmentDate).setHours(endTime[0], endTime[1], 0, 0);

    if (appointmentDate.getTime() < startAvailability || appointmentDate.getTime() >= endAvailability) {
      agent.add(`Nosso horário de atendimento na ${dayOfWeek}-feira é das ${daySchedule.startTime} às ${daySchedule.endTime}.`);
      return;
    }

    // 2. Verificar se o horário já está ocupado
    const appointmentEndTime = new Date(appointmentDate.getTime() + durationMinutes * 60000);

    const existingAppointments = await db.collection("appointments")
        .where("employeeId", "==", employeeId)
        .where("startDateTime", "<", admin.firestore.Timestamp.fromDate(appointmentEndTime))
        .where("startDateTime", ">=", admin.firestore.Timestamp.fromDate(appointmentDate))
        .get();

    if (!existingAppointments.empty) {
      agent.add("Desculpe, este horário já está ocupado. Por favor, tente outro.");
      return;
    }

    // 3. Tudo certo! Criar o agendamento
    const newAppointment = {
      clientId: "TODO: Pegar o ID do cliente logado", // Precisará ser passado do app
      employeeId: employeeId,
      serviceId: serviceSnapshot.docs[0].id,
      serviceName: serviceData.name,
      startDateTime: admin.firestore.Timestamp.fromDate(appointmentDate),
      endDateTime: admin.firestore.Timestamp.fromDate(appointmentEndTime),
      price: serviceData.price,
      status: "scheduled",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("appointments").add(newAppointment);

    const formattedDate = appointmentDate.toLocaleDateString('pt-BR');
    const formattedTime = appointmentDate.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

    agent.add(`Tudo certo! Seu agendamento de ${serviceName} foi marcado para ${formattedDate} às ${formattedTime}.`);
  }

  let intentMap = new Map();
  intentMap.set("agendar_servico", agendarServico);
  agent.handleRequest(intentMap);
});