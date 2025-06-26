// functions/index.js - VERSÃO COMPLETA E CORRIGIDA

// A linha mais importante - garantindo que TUDO que usamos seja importado
const {zonedTimeToUtc, utcToZonedTime, format} = require("date-fns-tz");
const functions = require("firebase-functions");
const {WebhookClient} = require("dialogflow-fulfillment");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();


/**
 * Função principal que lida com todas as requisições do Dialogflow.
 * @param {object} request O objeto de requisição.
 * @param {object} response O objeto de resposta.
 */
function agendariaWebhook(request, response) {
  const agent = new WebhookClient({request, response});

  /**
   * Lida com a intenção de agendar um serviço.
   * @param {WebhookClient} agent O agente do Dialogflow.
   * @return {Promise<void>}
   */
  async function agendarServico(agent) {
    const userId = agent.originalRequest?.payload?.firebase_uid;
    if (!userId) {
      agent.add("Desculpe, não consegui identificar seu usuário. Por favor, tente novamente.");
      return;
    }
    const {servico, date} = agent.parameters;
    const serviceName = servico;
    const timeZone = "America/Sao_Paulo";
    const appointmentDate = utcToZonedTime(new Date(date), timeZone);
    const serviceSnapshot = await db.collection("services").where("name", "==", serviceName).limit(1).get();
    if (serviceSnapshot.empty) {
      agent.add(`Desculpe, não oferecemos o serviço "${serviceName}".`);
      return;
    }
    const serviceData = serviceSnapshot.docs[0].data();
    const {employeeId, durationMinutes} = serviceData;
    const availabilityDoc = await db.collection("availabilities").doc(employeeId).get();
    if (!availabilityDoc.exists) {
      agent.add("Desculpe, o profissional não tem horários cadastrados.");
      return;
    }
    const weekdays = ["domingo", "segunda", "terca", "quarta", "quinta", "sexta", "sabado"];
    const dayOfWeek = weekdays[appointmentDate.getDay()];
    const daySchedule = availabilityDoc.data()[dayOfWeek];
    if (!daySchedule || !daySchedule.isAvailable) {
      agent.add(`Não há atendimento na ${dayOfWeek}-feira. Escolha outro dia.`);
      return;
    }
    const [startHour, startMinute] = daySchedule.startTime.split(":").map(Number);
    const [endHour, endMinute] = daySchedule.endTime.split(":").map(Number);
    const startAvailability = new Date(appointmentDate);
    startAvailability.setHours(startHour, startMinute, 0, 0);
    const endAvailability = new Date(appointmentDate);
    endAvailability.setHours(endHour, endMinute, 0, 0);
    if (appointmentDate < startAvailability || appointmentDate >= endAvailability) {
      agent.add(`Nosso horário na ${dayOfWeek}-feira é das ${daySchedule.startTime} às ${daySchedule.endTime}.`);
      return;
    }
    const appointmentDateUtc = zonedTimeToUtc(appointmentDate, timeZone);
    const appointmentEndTimeUtc = new Date(appointmentDateUtc.getTime() + durationMinutes * 60000);
    const existingAppointments = await db.collection("appointments")
        .where("employeeId", "==", employeeId)
        .where("startDateTime", "<", admin.firestore.Timestamp.fromDate(appointmentEndTimeUtc))
        .where("startDateTime", ">=", admin.firestore.Timestamp.fromDate(appointmentDateUtc))
        .get();
    if (!existingAppointments.empty) {
      agent.add("Desculpe, este horário já está ocupado. Tente outro.");
      return;
    }
    const newAppointment = {
      clientId: userId,
      employeeId,
      serviceId: serviceSnapshot.docs[0].id,
      serviceName,
      startDateTime: admin.firestore.Timestamp.fromDate(appointmentDateUtc),
      endDateTime: admin.firestore.Timestamp.fromDate(appointmentEndTimeUtc),
      price: serviceData.price,
      status: "scheduled",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection("appointments").add(newAppointment);
    const formattedDate = format(appointmentDate, "dd/MM/yyyy", {timeZone});
    const formattedTime = format(appointmentDate, "HH:mm", {timeZone});
    agent.add(`Tudo certo! Seu agendamento de ${serviceName} foi marcado para ${formattedDate} às ${formattedTime}.`);
  }

  /**
   * Lida com a intenção de listar os serviços disponíveis.
   * @param {WebhookClient} agent O agente do Dialogflow.
   * @return {Promise<void>}
   */
  async function listarServicos(agent) {
    const servicesSnapshot = await db.collection("services").get();
    if (servicesSnapshot.empty) {
      agent.add("No momento não temos nenhum serviço cadastrado.");
      return;
    }
    let responseText = "Claro! Aqui estão nossos serviços e preços:\n\n";
    servicesSnapshot.forEach((doc) => {
      const service = doc.data();
      const price = new Intl.NumberFormat("pt-BR", {style: "currency", currency: "BRL"}).format(service.price);
      responseText += `• ${service.name}: ${price}\n`;
    });
    agent.add(responseText);
  }

  /**
   * Lida com a intenção de consultar horários, considerando múltiplos funcionários.
   * @param {WebhookClient} agent O agente do Dialogflow.
   * @return {Promise<void>}
   */
  async function consultarHorarios(agent) {
    const {servico, date} = agent.parameters;
    const serviceName = servico;
    const timeZone = "America/Sao_Paulo";
    const requestedDate = utcToZonedTime(new Date(date), timeZone);
    const servicesSnapshot = await db.collection("services").where("name", "==", serviceName).get();
    if (servicesSnapshot.empty) {
      agent.add(`Desculpe, não oferecemos o serviço "${serviceName}".`);
      return;
    }
    const allAvailableSlots = [];
    for (const serviceDoc of servicesSnapshot.docs) {
      const serviceData = serviceDoc.data();
      const {employeeId, durationMinutes} = serviceData;
      const employeeDoc = await db.collection("users").doc(employeeId).get();
      const employeeName = employeeDoc.exists ? employeeDoc.data().name : "Profissional";
      const availabilityDoc = await db.collection("availabilities").doc(employeeId).get();
      if (!availabilityDoc.exists) continue;
      const weekdays = ["domingo", "segunda", "terca", "quarta", "quinta", "sexta", "sabado"];
      const dayOfWeek = weekdays[requestedDate.getDay()];
      const daySchedule = availabilityDoc.data()[dayOfWeek];
      if (!daySchedule || !daySchedule.isAvailable) continue;
      const startOfDay = new Date(requestedDate.getFullYear(), requestedDate.getMonth(), requestedDate.getDate());
      const endOfDay = new Date(startOfDay);
      endOfDay.setDate(endOfDay.getDate() + 1);
      const appointmentsSnapshot = await db.collection("appointments")
          .where("employeeId", "==", employeeId)
          .where("startDateTime", ">=", startOfDay)
          .where("startDateTime", "<", endOfDay)
          .get();
      const existingAppointments = appointmentsSnapshot.docs.map((doc) => ({
        start: doc.data().startDateTime.toDate(),
        end: doc.data().endDateTime.toDate(),
      }));
      const employeeSlots = [];
      const [startHour, startMinute] = daySchedule.startTime.split(":").map(Number);
      const [endHour, endMinute] = daySchedule.endTime.split(":").map(Number);
      let slotTime = new Date(startOfDay);
      slotTime.setHours(startHour, startMinute);
      const endWorkTime = new Date(startOfDay);
      endWorkTime.setHours(endHour, endMinute);
      while (slotTime < endWorkTime) {
        const slotEndTime = new Date(slotTime.getTime() + durationMinutes * 60000);
        if (slotEndTime > endWorkTime) break;
        const isOverlapping = existingAppointments.some((appt) => slotTime < appt.end && slotEndTime > appt.start);
        if (!isOverlapping) {
          employeeSlots.push(format(utcToZonedTime(slotTime, timeZone), "HH:mm", {timeZone}));
        }
        slotTime = new Date(slotTime.getTime() + 15 * 60000);
      }
      if (employeeSlots.length > 0) {
        allAvailableSlots.push({name: employeeName, slots: employeeSlots});
      }
    }
    if (allAvailableSlots.length === 0) {
      agent.add(`Desculpe, não encontrei horários livres para ${serviceName} neste dia. Gostaria de tentar outra data?`);
    } else {
      let responseText = `Encontrei horários para ${serviceName} com os seguintes profissionais:\n`;
      allAvailableSlots.forEach((employeeData) => {
        responseText += `\n• ${employeeData.name}: ${employeeData.slots.join(", ")}`;
      });
      responseText += `\n\nCom qual deles você gostaria de agendar?`;
      agent.add(responseText);
    }
  }

  const intentMap = new Map();
  intentMap.set("agendar_servico", agendarServico);
  intentMap.set("listar_servicos", listarServicos);
  intentMap.set("consultar_horarios_disponiveis", consultarHorarios);
  agent.handleRequest(intentMap);
}

exports.agendariaWebhook = functions.https.onRequest(agendariaWebhook);