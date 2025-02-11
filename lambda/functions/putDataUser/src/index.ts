// https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/javascript_dynamodb_code_examples.html
// https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/Package/-aws-sdk-lib-dynamodb/
// https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.DataTypes.html
// https://stackoverflow.com/questions/39451505/how-to-return-the-inserted-item-in-dynamodb

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  ScanCommand,
  UpdateCommand,
  ScanCommandOutput,
  UpdateCommandOutput,
} from '@aws-sdk/lib-dynamodb';

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

// environment variables
const region = process.env.REGION;
const tableName = process.env.TABLE_NAME;

// initialize DynamoDB client
const ddbClient = new DynamoDBClient({ region });

// initialize DynamoDB DocumentClient
const docClient = DynamoDBDocumentClient.from(ddbClient);

// Update the occupancy of a parking spot
export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('EVENT: \n' + JSON.stringify(event, null, 2));

  const type = event.pathParameters?.type;
  if (type === '' || (type !== 'add' && type !== 'remove')) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'Invalid request' }),
    };
  }

  const body = JSON.parse(event.body || '{}');

  // enter to parking - update an empty parking spot with car info
  if (type === 'add') {
    // validate the request body
    const { parkingSpot, vrn } = body;

    if (isNaN(parkingSpot) || !vrn) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Invalid request' }),
      };
    }

    const startTime = new Date().toISOString();

    try {
      const updateCommand = new UpdateCommand({
        TableName: tableName,
        Key: {
          parkingSpot: Number(parkingSpot),
        },
        UpdateExpression: 'set VRN = :VRN, startTime = :startTime',
        ConditionExpression: '(attribute_not_exists(VRN) OR VRN = :emptyString)',
        ExpressionAttributeValues: {
          ':VRN': vrn,
          ':startTime': startTime,
          ':emptyString': '', // define the empty string value
        },
        ReturnValues: 'ALL_NEW', // return the entire item as it appears AFTER the update has been applied
      });

      const updateResponse = (await docClient.send(updateCommand)) as UpdateCommandOutput;
      const attributes = updateResponse.Attributes;

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'car parking info has been logged',
          data: attributes,
        }),
      };
    } catch (error: any) {
      if (error.name === 'ConditionalCheckFailedException') {
        return {
          statusCode: 400,
          body: JSON.stringify({ message: 'parking spot is busy!' }),
        };
      } else {
        console.error('Unknown error:', error);
        return {
          statusCode: 500,
          body: JSON.stringify({ message: 'Internal Server Error' }),
        };
      }
    }
  }

  // exit from parking - release the parking spot
  if (type === 'remove') {
    // validate the request body
    const { vrn } = body;

    if (!vrn) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Invalid request' }),
      };
    }

    try {
      // find the parkingSpot according to the vrn
      const scanCommand = new ScanCommand({
        TableName: tableName,
        FilterExpression: 'VRN = :VRN',
        ExpressionAttributeValues: { ':VRN': vrn },
      });

      const scanResponse = (await docClient.send(scanCommand)) as ScanCommandOutput;

      if (scanResponse.Count === 0) {
        return {
          statusCode: 400,
          body: JSON.stringify({ message: 'car registration number is not valid!' }),
        };
      }

      const items = scanResponse.Items;
      const attributes = items && items[0];
      const parkingSpot = attributes?.parkingSpot;

      const updateCommand = new UpdateCommand({
        TableName: tableName,
        Key: {
          parkingSpot: Number(parkingSpot),
        },
        UpdateExpression: 'set VRN = :emptyString, startTime = :emptyString',
        ExpressionAttributeValues: {
          ':emptyString': '', // define the empty string value
        },
        ReturnValues: 'ALL_OLD', // return the entire item as it appears BEFORE the update has been applied
      });

      const updateResponse = (await docClient.send(updateCommand)) as UpdateCommandOutput;

      // calculate parking time
      const startTime = new Date(updateResponse?.Attributes?.startTime);
      const endTime = new Date();
      const parkTime = (endTime.getTime() - startTime.getTime()) / 60000; // in minutes

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'car has been removed',
          data: {
            startTime: startTime.toLocaleTimeString('en-GB', {
              timeZone: 'Europe/Rome',
            }),
            endTime: endTime.toLocaleTimeString('en-GB', {
              timeZone: 'Europe/Rome',
            }),
            parkTime: Math.round(parkTime), // round to the nearest integer
          },
        }),
      };
    } catch (error: any) {
      console.error('Unknown error:', error);
      return {
        statusCode: 500,
        body: JSON.stringify({ message: 'Internal Server Error' }),
      };
    }
  }

  return {
    statusCode: 500,
    body: JSON.stringify({ message: 'Internal Server Error' }),
  };
};
