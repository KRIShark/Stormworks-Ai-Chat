import os
from flask import Flask, request
from openai import OpenAI

app = Flask(__name__)

openai_api_key = os.getenv('OPENAI_API_KEY')

MAX_MSSG_LEN = 10

client = OpenAI(
    api_key=openai_api_key
)

messageLog = [{
        "role": "system",
        "content": [
            {
            "type": "text",
            "text": "You are a Stormworks Game Assistant. Your job is to assist the player in the context of Stormworks. You are also allowed to help the player with math or any questions that could be Stormworks related. You should always answer the player's questions first in the context of the game. Do not use tables or anything other than text responses, also no formatting or markup or special characters. Keep the response short, only 8 words."
            }
        ]
        }
    ]

@app.route('/chat', methods=['GET'])
def chat():

    #Rmove the first message if the length of the message log is greater than see MAX_MSSG_LEN
    if len(messageLog) > MAX_MSSG_LEN:
        messageLog.pop(0)
    
    text = request.args.get('text')

    messageLog.append({
            "role": "user",
            "content": [
                {
                "type": "text",
                "text": text
                }
            ]
        })

    response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=messageLog,
        temperature=1,
        max_tokens=20,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0,
        response_format={
            "type": "text"
        }
    )

    print("user text", text)
    print("response", response.choices[0].message.content)

    messageLog.append({
      "role": "assistant",
      "content": [
        {
          "type": "text",
          "text": response.choices[0].message.content
        }
      ]
    })

    return response.choices[0].message.content

if __name__ == '__main__':
    app.run(port=5000)